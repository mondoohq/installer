# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Command-line interface for auto-update tests."""

from __future__ import annotations

import argparse
import sys

from .constants import (
    DEFAULT_BASE_VERSIONS,
    DEFAULT_RELEASES_URL,
    DEFAULT_STABLE_RELEASES_URL,
)
from .distros import DISTROS, filter_distros
from .runners import (
    run_aur_tests,
    run_auto_update_tests,
    run_install_sh_upgrade_tests,
    run_mondoo_pkg_tests,
    run_self_upgrade_tests,
    run_upgrade_tests,
)
from .utils import get_latest_version, print_header

# Valid test types
VALID_TEST_TYPES = {
    "auto-update",
    "mondoo-pkg",
    "upgrade",
    "self-upgrade",
    "aur",
    "install-sh-upgrade",
}


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Test mql/cnspec auto-update and mondoo metapackage via Docker containers",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Test types:
  auto-update        Test auto-update functionality
  mondoo-pkg         Test mondoo metapackage installation
  upgrade            Test upgrade from cnquery to mql
  self-upgrade       Test self-upgrade (requires --self-upgrade-from)
  aur                Test AUR installation (Arch Linux only)
  install-sh-upgrade Test upgrade via install.sh (requires --install-sh-upgrade-from)
  all                Run all test types

Examples:
  # Run all tests
  %(prog)s --install-version 13.0.0 --tests all

  # Run specific tests
  %(prog)s --install-version 13.0.0 --tests mondoo-pkg,upgrade

  # Run all except AUR tests
  %(prog)s --install-version 13.0.0 --tests all --skip-tests aur

  # Run install.sh upgrade test (--install-sh-upgrade-from implies the test)
  %(prog)s --install-version 13.0.0 --install-sh-upgrade-from 12.0.0
""",
    )
    parser.add_argument(
        "--install-version",
        required=True,
        help="Version to install/test, e.g. 13.0.0-rc2",
    )
    parser.add_argument(
        "--tests",
        default="",
        metavar="TYPES",
        help="Comma-separated test types to run (see list below), or 'all'",
    )
    parser.add_argument(
        "--skip-tests",
        default="",
        metavar="TYPES",
        help="Comma-separated test types to skip (use with --tests all)",
    )
    parser.add_argument(
        "--releases-url",
        default=DEFAULT_RELEASES_URL,
        help=f"Releases base URL (default: {DEFAULT_RELEASES_URL})",
    )
    parser.add_argument(
        "--base-versions",
        default=DEFAULT_BASE_VERSIONS,
        help=f"Comma-separated list of versions to upgrade from (default: {DEFAULT_BASE_VERSIONS})",
    )
    parser.add_argument(
        "--stable-releases-url",
        default=DEFAULT_STABLE_RELEASES_URL,
        help=f"Stable releases URL for base packages in upgrade tests (default: {DEFAULT_STABLE_RELEASES_URL})",
    )
    parser.add_argument(
        "--fail-fast",
        action="store_true",
        help="Stop after the first failure",
    )
    parser.add_argument(
        "--self-upgrade-from",
        default="",
        help="Version to install before triggering self-upgrade (e.g. 13.0.0-rc5). Implies --tests self-upgrade.",
    )
    parser.add_argument(
        "--install-sh-upgrade-from",
        default="",
        help="Version to install before upgrading via install.sh (e.g. 12.0.0). Implies --tests install-sh-upgrade.",
    )
    parser.add_argument(
        "--distro",
        action="append",
        default=[],
        metavar="FILTER",
        help="Only run tests for distros matching FILTER (case-insensitive). Can be repeated.",
    )
    parser.add_argument(
        "--shell-on-failure",
        action="store_true",
        help="Drop into an interactive bash shell inside the container on failure.",
    )
    parser.add_argument(
        "--aur-test",
        choices=["mql-makepkg", "cnspec-yay"],
        help="Run only a specific AUR test (Arch Linux only)",
    )
    parser.add_argument(
        "--use-local-install-sh",
        action="store_true",
        help="Use the local install.sh instead of downloading from install.mondoo.com (for testing install.sh changes)",
    )
    return parser.parse_args()


def parse_test_types(args: argparse.Namespace) -> set[str]:
    """Parse and validate test types from arguments."""
    # Parse --tests
    test_types: set[str] = set()
    if args.tests:
        for t in args.tests.split(","):
            t = t.strip()
            if t == "all":
                test_types = VALID_TEST_TYPES.copy()
                break
            if t and t not in VALID_TEST_TYPES:
                print(f"ERROR: unknown test type '{t}'. Valid types: {', '.join(sorted(VALID_TEST_TYPES))}, all")
                sys.exit(1)
            if t:
                test_types.add(t)

    # Parse --skip-tests
    if args.skip_tests:
        for t in args.skip_tests.split(","):
            t = t.strip()
            if t and t not in VALID_TEST_TYPES:
                print(f"ERROR: unknown test type '{t}'. Valid types: {', '.join(sorted(VALID_TEST_TYPES))}")
                sys.exit(1)
            test_types.discard(t)

    # Version params imply their test type
    if args.self_upgrade_from:
        test_types.add("self-upgrade")
    if args.install_sh_upgrade_from:
        test_types.add("install-sh-upgrade")

    return test_types


def main() -> None:
    """Main entry point for the CLI."""
    args = parse_args()

    install_version = args.install_version.lstrip("v")
    base_versions = [v.strip().lstrip("v") for v in args.base_versions.split(",") if v.strip()]

    # Parse test types
    test_types = parse_test_types(args)
    if not test_types:
        print("ERROR: no tests selected. Use --tests to specify test types, or use version flags like --self-upgrade-from.")
        print("Run with --help for usage information.")
        sys.exit(1)

    print(f"Selected tests: {', '.join(sorted(test_types))}")

    # Filter distros if requested
    distros = DISTROS
    if args.distro:
        distros = filter_distros(DISTROS, args.distro)
        if not distros:
            print(f"ERROR: no distros matched filters: {args.distro}")
            sys.exit(1)
        print(f"Filtered to distros: {[d.name for d in distros]}")

    failures: list[str] = []

    # Auto-update tests
    if "auto-update" in test_types:
        print(f"Fetching latest versions from {args.releases_url}...")
        mql_latest = get_latest_version("mql", args.releases_url)
        cnspec_latest = get_latest_version("cnspec", args.releases_url)

        print(f"  install version : {install_version}")
        print(f"  mql latest      : {mql_latest}")
        print(f"  cnspec latest   : {cnspec_latest}")

        print_header("AUTO-UPDATE TESTS")
        failures.extend(run_auto_update_tests(
            distros, install_version, args.releases_url,
            mql_latest, cnspec_latest,
            args.shell_on_failure, args.fail_fast,
        ))

        if failures and args.fail_fast:
            print_header(f"FAILED on: {', '.join(failures)}")
            sys.exit(1)

    # Mondoo metapackage tests
    if "mondoo-pkg" in test_types:
        print_header("MONDOO METAPACKAGE TESTS")
        failures.extend(run_mondoo_pkg_tests(
            distros, install_version, args.releases_url,
            args.shell_on_failure, args.fail_fast,
        ))

        if failures and args.fail_fast:
            print_header(f"FAILED on: {', '.join(failures)}")
            sys.exit(1)

    # Upgrade tests
    if "upgrade" in test_types:
        print_header("UPGRADE TESTS")
        print(f"  base versions   : {', '.join(base_versions)}")
        print(f"  stable url      : {args.stable_releases_url}")
        print(f"  target version  : {install_version}")

        failures.extend(run_upgrade_tests(
            distros, base_versions, install_version,
            args.stable_releases_url, args.releases_url,
            args.shell_on_failure, args.fail_fast,
        ))

        if failures and args.fail_fast:
            print_header(f"FAILED on: {', '.join(failures)}")
            sys.exit(1)

    # Self-upgrade tests
    if "self-upgrade" in test_types:
        self_upgrade_from = args.self_upgrade_from.lstrip("v")
        print_header("SELF-UPGRADE TESTS")

        if not self_upgrade_from:
            print("  Skipped: --self-upgrade-from not specified")
        else:
            print(f"  from version    : {self_upgrade_from}")
            print(f"  target version  : {install_version}")
            print(f"  releases url    : {args.releases_url}")

            failures.extend(run_self_upgrade_tests(
                distros, self_upgrade_from, install_version,
                args.releases_url, args.shell_on_failure, args.fail_fast,
            ))

            if failures and args.fail_fast:
                print_header(f"FAILED on: {', '.join(failures)}")
                sys.exit(1)

    # Install.sh upgrade tests
    if "install-sh-upgrade" in test_types:
        install_sh_upgrade_from = args.install_sh_upgrade_from.lstrip("v")
        print_header("INSTALL.SH UPGRADE TESTS")

        if not install_sh_upgrade_from:
            print("  Skipped: --install-sh-upgrade-from not specified")
        else:
            print(f"  from version    : {install_sh_upgrade_from}")
            print(f"  target version  : {install_version}")

            failures.extend(run_install_sh_upgrade_tests(
                distros, install_sh_upgrade_from, install_version,
                args.stable_releases_url, args.releases_url,
                args.shell_on_failure, args.fail_fast,
                use_local_install_sh=args.use_local_install_sh,
            ))

            if failures and args.fail_fast:
                print_header(f"FAILED on: {', '.join(failures)}")
                sys.exit(1)

    # AUR tests (Arch Linux only)
    if "aur" in test_types:
        arch_distros = [d for d in distros if d.pkg_mgr_name == "pacman"]
        if arch_distros:
            print_header("AUR TESTS (Arch Linux)")
            print(f"  target version  : {install_version}")
            if args.aur_test:
                print(f"  test            : {args.aur_test}")

            failures.extend(run_aur_tests(
                distros, install_version, args.releases_url,
                args.shell_on_failure, args.fail_fast,
                aur_test=args.aur_test,
            ))

            if failures and args.fail_fast:
                print_header(f"FAILED on: {', '.join(failures)}")
                sys.exit(1)

    # Final summary
    print_header("SUMMARY")
    if failures:
        print(f"FAILED on: {', '.join(failures)}")
        sys.exit(1)
    print("All tests passed!")
