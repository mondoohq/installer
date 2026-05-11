# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Test runner functions for each test type."""

from __future__ import annotations

from typing import TYPE_CHECKING

from .docker import DockerRunner
from .scripts import ScriptBuilder
from .utils import print_test_header

if TYPE_CHECKING:
    from .distros import Distro


def run_auto_update_tests(
    distros: list[Distro],
    install_version: str,
    releases_url: str,
    mql_latest: str,
    cnspec_latest: str,
    shell_on_failure: bool,
    fail_fast: bool,
) -> list[str]:
    """Run auto-update tests. Returns list of failures."""
    failures = []

    for distro in distros:
        print_test_header(distro)

        builder = ScriptBuilder(distro.pkg_mgr, releases_url)
        script = builder.build_auto_update_script(install_version, mql_latest, cnspec_latest)

        runner = DockerRunner(distro, shell_on_failure)
        if runner.run(script):
            print(f"\nPASS: {distro.name}")
        else:
            print(f"\nFAIL: {distro.name}")
            failures.append(f"{distro.name} (auto-update)")
            if fail_fast:
                break

    return failures


def run_mondoo_pkg_tests(
    distros: list[Distro],
    version: str,
    releases_url: str,
    shell_on_failure: bool,
    fail_fast: bool,
) -> list[str]:
    """Run mondoo metapackage tests. Returns list of failures."""
    failures = []

    for distro in distros:
        # Skip Arch Linux - packages are in AUR, not on releases.mondoo.com
        if distro.pkg_mgr_name == "pacman":
            print(f"\nSKIP: {distro.name} (mondoo pkg) - AUR packages tested separately")
            continue

        print_test_header(distro, "mondoo pkg")

        builder = ScriptBuilder(distro.pkg_mgr, releases_url)
        script = builder.build_mondoo_pkg_script(version)

        runner = DockerRunner(distro, shell_on_failure)
        if runner.run(script):
            print(f"\nPASS: {distro.name} (mondoo pkg)")
        else:
            print(f"\nFAIL: {distro.name} (mondoo pkg)")
            failures.append(f"{distro.name} (mondoo pkg)")
            if fail_fast:
                break

    return failures


def run_upgrade_tests(
    distros: list[Distro],
    base_versions: list[str],
    target_version: str,
    stable_url: str,
    releases_url: str,
    shell_on_failure: bool,
    fail_fast: bool,
) -> list[str]:
    """Run upgrade tests. Returns list of failures."""
    failures = []

    # Run AUR-based upgrade test for Arch Linux (only once, not per base_version)
    arch_distros = [d for d in distros if d.pkg_mgr_name == "pacman"]
    for distro in arch_distros:
        print_test_header(distro, "AUR upgrade cnquery->mql")

        builder = ScriptBuilder(distro.pkg_mgr, releases_url)
        script = builder.build_aur_upgrade_script(target_version)

        runner = DockerRunner(distro, shell_on_failure)
        if runner.run(script):
            print(f"\nPASS: {distro.name} (AUR upgrade cnquery->mql)")
        else:
            print(f"\nFAIL: {distro.name} (AUR upgrade cnquery->mql)")
            failures.append(f"{distro.name} (AUR upgrade cnquery->mql)")
            if fail_fast:
                return failures

    # Run package-based upgrade tests for other distros
    for base_version in base_versions:
        for distro in distros:
            # Skip Arch Linux - already tested above with AUR
            if distro.pkg_mgr_name == "pacman":
                continue

            print_test_header(distro, f"upgrade from {base_version}")

            builder = ScriptBuilder(distro.pkg_mgr, releases_url)
            script = builder.build_upgrade_script(base_version, target_version, stable_url)

            runner = DockerRunner(distro, shell_on_failure)
            if runner.run(script):
                print(f"\nPASS: {distro.name} (upgrade from {base_version})")
            else:
                print(f"\nFAIL: {distro.name} (upgrade from {base_version})")
                failures.append(f"{distro.name} (upgrade from {base_version})")
                if fail_fast:
                    return failures

    return failures


def run_self_upgrade_tests(
    distros: list[Distro],
    from_version: str,
    target_version: str,
    releases_url: str,
    shell_on_failure: bool,
    fail_fast: bool,
) -> list[str]:
    """Run self-upgrade tests. Returns list of failures."""
    failures = []

    for distro in distros:
        print_test_header(distro, f"self-upgrade from {from_version}")

        builder = ScriptBuilder(distro.pkg_mgr, releases_url)
        script = builder.build_self_upgrade_script(from_version, target_version)

        runner = DockerRunner(distro, shell_on_failure)
        if runner.run(script):
            print(f"\nPASS: {distro.name} (self-upgrade from {from_version})")
        else:
            print(f"\nFAIL: {distro.name} (self-upgrade from {from_version})")
            failures.append(f"{distro.name} (self-upgrade from {from_version})")
            if fail_fast:
                break

    return failures


def run_install_sh_upgrade_tests(
    distros: list[Distro],
    base_version: str,
    target_version: str,
    stable_url: str,
    releases_url: str,
    shell_on_failure: bool,
    fail_fast: bool,
    use_local_install_sh: bool = False,
) -> list[str]:
    """Run install.sh upgrade tests. Returns list of failures.

    Installs cnquery from releases.mondoo.com, then upgrades to mql via
    install.sh (either local or from install.mondoo.com).
    """
    failures = []

    for distro in distros:
        # Skip Arch Linux - install.sh doesn't support pacman
        if distro.pkg_mgr_name == "pacman":
            print(f"\nSKIP: {distro.name} (install.sh upgrade) - not supported for pacman")
            continue

        print_test_header(distro, f"install.sh upgrade from {base_version}")

        builder = ScriptBuilder(distro.pkg_mgr, releases_url)
        script = builder.build_install_sh_upgrade_script(
            base_version, target_version, stable_url,
            use_local=use_local_install_sh,
        )

        runner = DockerRunner(distro, shell_on_failure)
        if runner.run(script, mount_workdir=use_local_install_sh):
            print(f"\nPASS: {distro.name} (install.sh upgrade from {base_version})")
        else:
            print(f"\nFAIL: {distro.name} (install.sh upgrade from {base_version})")
            failures.append(f"{distro.name} (install.sh upgrade from {base_version})")
            if fail_fast:
                break

    return failures


def run_aur_tests(
    distros: list[Distro],
    target_version: str,
    releases_url: str,
    shell_on_failure: bool,
    fail_fast: bool,
    aur_test: str | None = None,
) -> list[str]:
    """Run AUR installation tests (Arch Linux only). Returns list of failures.

    Args:
        aur_test: If specified, run only this test ("mql-makepkg" or "cnspec-yay")
    """
    failures = []

    # Filter to Arch Linux only
    arch_distros = [d for d in distros if d.pkg_mgr_name == "pacman"]
    if not arch_distros:
        return failures

    for distro in arch_distros:
        builder = ScriptBuilder(distro.pkg_mgr, releases_url)

        # Test 1: Install mql via makepkg
        if aur_test is None or aur_test == "mql-makepkg":
            print_test_header(distro, "AUR mql makepkg")

            script = builder.build_aur_mql_install_script(target_version)

            runner = DockerRunner(distro, shell_on_failure)
            if runner.run(script):
                print(f"\nPASS: {distro.name} (AUR mql makepkg)")
            else:
                print(f"\nFAIL: {distro.name} (AUR mql makepkg)")
                failures.append(f"{distro.name} (AUR mql makepkg)")
                if fail_fast:
                    return failures

        # Test 2: Install cnspec via yay (also installs mql as dependency)
        if aur_test is None or aur_test == "cnspec-yay":
            print_test_header(distro, "AUR cnspec yay")

            script = builder.build_aur_cnspec_yay_script(target_version)

            runner = DockerRunner(distro, shell_on_failure)
            if runner.run(script):
                print(f"\nPASS: {distro.name} (AUR cnspec yay)")
            else:
                print(f"\nFAIL: {distro.name} (AUR cnspec yay)")
                failures.append(f"{distro.name} (AUR cnspec yay)")
                if fail_fast:
                    return failures

    return failures
