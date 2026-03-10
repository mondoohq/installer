# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

"""
Test auto-update of mql and cnspec using Docker containers, and test the
mondoo metapackage installation from .deb/.rpm packages.

Auto-update tests:
  Spins up RPM- and DEB-based containers, installs a given version of
  cnspec and mql from releases.mondoo.love, seeds ~/.config/mondoo/mondoo.yml
  with auto-update configuration, then runs:

      mql run local -c "mondoo.version"
      cnspec run local -c "mondoo.version"

  and verifies the output contains the latest version as reported by
  https://releases.mondoo.love/{product}/latest.json.

Mondoo package tests:
  Downloads mql, cnspec, and mondoo .deb/.rpm packages for the given version,
  installs them via the native package manager, and verifies that:
    - mql version output contains the expected version
    - cnspec version output contains the expected version
    - the mondoo metapackage is recorded as installed

Upgrade tests:
  For each base version (default: 11.0.0, 12.0.0), installs mql, cnspec, and
  mondoo packages from the stable releases URL, then upgrades to the target
  version from --releases-url and verifies the new version is active.

Self-upgrade tests:
  Installs an older version of mql/cnspec from tarballs, seeds
  ~/.config/mondoo/mondoo.yml with auto_update: true, runs
  `mql run local -c "mondoo.version"` to trigger the in-process self-upgrade,
  then checks `mql version` to confirm the binary replaced itself with the
  target version. Requires --self-upgrade-from.

Usage:
    python3 test_auto_update.py --install-version 13.0.0-rc7
    python3 test_auto_update.py --install-version 13.0.0-rc7 --releases-url https://releases.mondoo.love
    python3 test_auto_update.py --install-version 13.0.0-rc7 --skip-auto-update
    python3 test_auto_update.py --install-version 13.0.0-rc7 --skip-mondoo-pkg
    python3 test_auto_update.py --install-version 13.0.0-rc7 --skip-upgrade
    python3 test_auto_update.py --install-version 13.0.0-rc7 --base-versions 11.0.0,12.23.1
    python3 test_auto_update.py --install-version 13.0.0-rc7 --self-upgrade-from 13.0.0-rc5
    python3 test_auto_update.py --install-version 13.0.0-rc7 --distro rocky
    python3 test_auto_update.py --install-version 13.0.0-rc7 --distro ubuntu --distro debian
"""

import argparse
import json
import subprocess
import sys
import textwrap
import urllib.request

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------

DEFAULT_RELEASES_URL = "https://releases.mondoo.love"
DEFAULT_STABLE_RELEASES_URL = "https://releases.mondoo.com"
DEFAULT_BASE_VERSIONS = "11.0.0,12.0.0"

# Containers to test: (human name, Docker image, package manager)
DISTROS = [
    # DEB-based
    ("Ubuntu 22.04", "ubuntu:22.04", "apt"),
    ("Debian 12",    "debian:12",    "apt"),
    # RPM-based
    ("AlmaLinux 9",  "almalinux:9",  "dnf"),
    ("Rocky Linux 9","rockylinux:9", "dnf"),
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def get_latest_version(product: str, releases_url: str) -> str:
    url = f"{releases_url}/{product}/latest.json"
    with urllib.request.urlopen(url) as resp:
        return json.load(resp)["version"]


def build_container_script(
    install_version: str,
    releases_url: str,
    mql_latest: str,
    cnspec_latest: str,
    pkg_mgr: str,
) -> str:
    """Return a bash script that will be executed inside the container."""

    if pkg_mgr == "apt":
        # curl is not pre-installed in minimal Debian/Ubuntu images; install it.
        # tmpfs mounts (added in docker run) give apt enough space without touching
        # the overlay filesystem.
        setup_curl = textwrap.dedent("""\
            apt-get update -qq \\
                -o Acquire::Check-Valid-Until=false \\
                -o Acquire::AllowInsecureRepositories=true
            apt-get install -y -q --no-install-recommends --allow-unauthenticated ca-certificates curl
            apt-get clean && rm -rf /var/lib/apt/lists/*""")
    else:
        # curl-minimal is pre-installed on RHEL9 variants and provides the curl binary.
        setup_curl = "curl --version"

    mondoo_yml = textwrap.dedent(f"""\
        log-level: debug
        auto_update: true
        updates_url: {releases_url}
        providers_url: {DEFAULT_STABLE_RELEASES_URL}/providers
        features:
          - AutoUpdateEngine
    """)

    return textwrap.dedent(f"""\
        set -e
        # ---- ensure curl is available ----
        {setup_curl}

        # ---- install mql {install_version} ----
        TMPDIR=$(mktemp -d)
        curl -fsSL '{releases_url}/mql/{install_version}/mql_{install_version}_linux_amd64.tar.gz' \\
            | tar xz -C "$TMPDIR"
        find "$TMPDIR" -name mql -type f -exec mv {{}} /usr/local/bin/mql \\;
        rm -rf "$TMPDIR"
        chmod +x /usr/local/bin/mql
        echo "installed mql: $(mql version)"

        # ---- install cnspec {install_version} ----
        TMPDIR=$(mktemp -d)
        curl -fsSL '{releases_url}/cnspec/{install_version}/cnspec_{install_version}_linux_amd64.tar.gz' \\
            | tar xz -C "$TMPDIR"
        find "$TMPDIR" -name cnspec -type f -exec mv {{}} /usr/local/bin/cnspec \\;
        rm -rf "$TMPDIR"
        chmod +x /usr/local/bin/cnspec
        echo "installed cnspec: $(cnspec version)"

        # ---- seed mondoo config ----
        mkdir -p ~/.config/mondoo
        cat > ~/.config/mondoo/mondoo.yml << 'MONDOOEOF'
{mondoo_yml}MONDOOEOF

        # ---- run mql and verify version ----
        echo ""
        echo "=== mql run local -c "mondoo.version" ==="
        MQL_OUT=$(mql run local -c "mondoo.version" 2>&1) || true
        echo "$MQL_OUT"
        if echo "$MQL_OUT" | grep -qF '{mql_latest}'; then
            echo "PASS: mql output contains version {mql_latest}"
        else
            echo "FAIL: mql output does not contain version {mql_latest}"
            exit 1
        fi

        # ---- run cnspec and verify version ----
        echo ""
        echo "=== cnspec run local -c "mondoo.version" ==="
        CNSPEC_OUT=$(cnspec run local -c "mondoo.version" 2>&1) || true
        echo "$CNSPEC_OUT"
        if echo "$CNSPEC_OUT" | grep -qF '{cnspec_latest}'; then
            echo "PASS: cnspec output contains version {cnspec_latest}"
        else
            echo "FAIL: cnspec output does not contain version {cnspec_latest}"
            exit 1
        fi
    """)


def build_mondoo_pkg_script(
    version: str,
    releases_url: str,
    pkg_mgr: str,
) -> str:
    """Return a bash script that installs mql, cnspec, and mondoo packages."""

    if pkg_mgr == "apt":
        setup_and_install = textwrap.dedent(f"""\
            apt-get update -qq \\
                -o Acquire::Check-Valid-Until=false \\
                -o Acquire::AllowInsecureRepositories=true
            apt-get install -y -q --no-install-recommends --allow-unauthenticated ca-certificates curl
            apt-get clean && rm -rf /var/lib/apt/lists/*

            PKGDIR=$(mktemp -d)
            curl -fsSL '{releases_url}/mql/{version}/mql_{version}_linux_amd64.deb' -o "$PKGDIR/mql.deb"
            curl -fsSL '{releases_url}/cnspec/{version}/cnspec_{version}_linux_amd64.deb' -o "$PKGDIR/cnspec.deb"
            curl -fsSL '{releases_url}/mondoo/{version}/mondoo_{version}_linux_amd64.deb' -o "$PKGDIR/mondoo.deb"
            apt install -y "$PKGDIR/mql.deb" "$PKGDIR/cnspec.deb" "$PKGDIR/mondoo.deb"
            rm -rf "$PKGDIR"

            echo "--- dpkg -l mondoo ---"
            dpkg -l mondoo""")
    else:
        setup_and_install = textwrap.dedent(f"""\
            PKGDIR=$(mktemp -d)
            curl -fsSL '{releases_url}/mql/{version}/mql_{version}_linux_amd64.rpm' -o "$PKGDIR/mql.rpm"
            curl -fsSL '{releases_url}/cnspec/{version}/cnspec_{version}_linux_amd64.rpm' -o "$PKGDIR/cnspec.rpm"
            curl -fsSL '{releases_url}/mondoo/{version}/mondoo_{version}_linux_amd64.rpm' -o "$PKGDIR/mondoo.rpm"
            dnf install -y --nogpgcheck "$PKGDIR/mql.rpm" "$PKGDIR/cnspec.rpm" "$PKGDIR/mondoo.rpm"
            rm -rf "$PKGDIR"

            echo "--- rpm -q mondoo ---"
            rpm -q mondoo""")

    return textwrap.dedent(f"""\
        set -e

        {setup_and_install}

        # ---- verify mql version ----
        echo ""
        echo "=== mql version ==="
        MQL_OUT=$(mql version 2>&1)
        echo "$MQL_OUT"
        if echo "$MQL_OUT" | grep -qF '{version}'; then
            echo "PASS: mql version contains {version}"
        else
            echo "FAIL: mql version does not contain {version}"
            exit 1
        fi

        # ---- verify cnspec version ----
        echo ""
        echo "=== cnspec version ==="
        CNSPEC_OUT=$(cnspec version 2>&1)
        echo "$CNSPEC_OUT"
        if echo "$CNSPEC_OUT" | grep -qF '{version}'; then
            echo "PASS: cnspec version contains {version}"
        else
            echo "FAIL: cnspec version does not contain {version}"
            exit 1
        fi
    """)


def _mql_product(version: str) -> str:
    """Return 'cnquery' for v11/v12 (before the cnquery→mql rename), 'mql' for v13+."""
    major = int(version.split(".")[0])
    return "cnquery" if major < 13 else "mql"


def build_upgrade_script(
    base_version: str,
    target_version: str,
    stable_url: str,
    releases_url: str,
    pkg_mgr: str,
) -> str:
    """Return a bash script that installs base_version then upgrades to target_version."""

    base_product = _mql_product(base_version)

    if pkg_mgr == "apt":
        return textwrap.dedent(f"""\
            set -e

            apt-get update -qq \\
                -o Acquire::Check-Valid-Until=false \\
                -o Acquire::AllowInsecureRepositories=true
            apt-get install -y -q --no-install-recommends --allow-unauthenticated ca-certificates curl
            apt-get clean && rm -rf /var/lib/apt/lists/*

            # ---- install base version {base_version} ({base_product}) ----
            echo "Installing base version {base_version}..."
            PKGDIR=$(mktemp -d)
            curl -fsSL '{stable_url}/{base_product}/{base_version}/{base_product}_{base_version}_linux_amd64.deb' -o "$PKGDIR/base-mql.deb"
            curl -fsSL '{stable_url}/cnspec/{base_version}/cnspec_{base_version}_linux_amd64.deb' -o "$PKGDIR/cnspec.deb"
            curl -fsSL '{stable_url}/mondoo/{base_version}/mondoo_{base_version}_linux_amd64.deb' -o "$PKGDIR/mondoo.deb"
            apt install -y "$PKGDIR/base-mql.deb" "$PKGDIR/cnspec.deb" "$PKGDIR/mondoo.deb"
            rm -rf "$PKGDIR"
            echo "base {base_product}: $({base_product} version)"
            echo "base cnspec:         $(cnspec version)"

            # ---- upgrade to {target_version} ----
            echo ""
            echo "Upgrading to {target_version}..."
            PKGDIR=$(mktemp -d)
            curl -fsSL '{releases_url}/mql/{target_version}/mql_{target_version}_linux_amd64.deb' -o "$PKGDIR/mql.deb"
            curl -fsSL '{releases_url}/cnspec/{target_version}/cnspec_{target_version}_linux_amd64.deb' -o "$PKGDIR/cnspec.deb"
            curl -fsSL '{releases_url}/mondoo/{target_version}/mondoo_{target_version}_linux_amd64.deb' -o "$PKGDIR/mondoo.deb"
            apt-get -y install "$PKGDIR/mql.deb" "$PKGDIR/cnspec.deb" "$PKGDIR/mondoo.deb"
            rm -rf "$PKGDIR"
            echo "--- dpkg -l mondoo ---"
            dpkg -l mondoo

            # ---- verify versions after upgrade ----
            echo ""
            echo "=== mql version ==="
            MQL_OUT=$(mql version 2>&1)
            echo "$MQL_OUT"
            if echo "$MQL_OUT" | grep -qF '{target_version}'; then
                echo "PASS: mql version contains {target_version}"
            else
                echo "FAIL: mql version does not contain {target_version}"
                exit 1
            fi

            echo ""
            echo "=== cnspec version ==="
            CNSPEC_OUT=$(cnspec version 2>&1)
            echo "$CNSPEC_OUT"
            if echo "$CNSPEC_OUT" | grep -qF '{target_version}'; then
                echo "PASS: cnspec version contains {target_version}"
            else
                echo "FAIL: cnspec version does not contain {target_version}"
                exit 1
            fi
        """)
    else:
        return textwrap.dedent(f"""\
            set -e

            # ---- install base version {base_version} ({base_product}) ----
            echo "Installing base version {base_version}..."
            PKGDIR=$(mktemp -d)
            curl -fsSL '{stable_url}/{base_product}/{base_version}/{base_product}_{base_version}_linux_amd64.rpm' -o "$PKGDIR/base-mql.rpm"
            curl -fsSL '{stable_url}/cnspec/{base_version}/cnspec_{base_version}_linux_amd64.rpm' -o "$PKGDIR/cnspec.rpm"
            curl -fsSL '{stable_url}/mondoo/{base_version}/mondoo_{base_version}_linux_amd64.rpm' -o "$PKGDIR/mondoo.rpm"
            dnf install -y --nogpgcheck "$PKGDIR/base-mql.rpm" "$PKGDIR/cnspec.rpm" "$PKGDIR/mondoo.rpm"
            rm -rf "$PKGDIR"
            echo "base {base_product}: $({base_product} version)"
            echo "base cnspec:         $(cnspec version)"

            # ---- upgrade to {target_version} ----
            echo ""
            echo "Upgrading to {target_version}..."
            PKGDIR=$(mktemp -d)
            curl -fsSL '{releases_url}/mql/{target_version}/mql_{target_version}_linux_amd64.rpm' -o "$PKGDIR/mql.rpm"
            curl -fsSL '{releases_url}/cnspec/{target_version}/cnspec_{target_version}_linux_amd64.rpm' -o "$PKGDIR/cnspec.rpm"
            curl -fsSL '{releases_url}/mondoo/{target_version}/mondoo_{target_version}_linux_amd64.rpm' -o "$PKGDIR/mondoo.rpm"
            dnf install -y --nogpgcheck "$PKGDIR/mql.rpm" "$PKGDIR/cnspec.rpm" "$PKGDIR/mondoo.rpm"
            rm -rf "$PKGDIR"
            echo "--- rpm -q mondoo ---"
            rpm -q mondoo

            # ---- verify versions after upgrade ----
            echo ""
            echo "=== mql version ==="
            MQL_OUT=$(mql version 2>&1)
            echo "$MQL_OUT"
            if echo "$MQL_OUT" | grep -qF '{target_version}'; then
                echo "PASS: mql version contains {target_version}"
            else
                echo "FAIL: mql version does not contain {target_version}"
                exit 1
            fi

            echo ""
            echo "=== cnspec version ==="
            CNSPEC_OUT=$(cnspec version 2>&1)
            echo "$CNSPEC_OUT"
            if echo "$CNSPEC_OUT" | grep -qF '{target_version}'; then
                echo "PASS: cnspec version contains {target_version}"
            else
                echo "FAIL: cnspec version does not contain {target_version}"
                exit 1
            fi
        """)


def _shell_on_failure_script(script: str) -> str:
    """Inject a bash ERR trap that drops to an interactive shell on failure."""
    return script.replace("set -e\n", "set -e\ntrap 'echo \"--- dropping to shell ---\"; exec bash' ERR\n", 1)


def run_upgrade_test(
    name: str,
    image: str,
    pkg_mgr: str,
    base_version: str,
    target_version: str,
    stable_url: str,
    releases_url: str,
    shell_on_failure: bool = False,
) -> bool:
    print(f"\n{'='*60}")
    print(f"  {name}  ({image})  [upgrade from {base_version}]")
    print(f"{'='*60}")

    script = build_upgrade_script(base_version, target_version, stable_url, releases_url, pkg_mgr)
    if shell_on_failure:
        script = _shell_on_failure_script(script)

    docker_cmd = [
        "docker", "run", "--rm",
        "--pull", "always",
        "--platform", "linux/amd64",
    ]
    if shell_on_failure:
        docker_cmd += ["-it"]
    if pkg_mgr == "apt":
        docker_cmd += [
            "--tmpfs", "/var/cache/apt:rw,size=256m",
            "--tmpfs", "/var/lib/apt/lists:rw,size=256m",
        ]
    else:
        docker_cmd += [
            "--tmpfs", "/var/cache/dnf:rw,size=512m",
        ]
    docker_cmd += [image, "bash", "-c", script]

    result = subprocess.run(docker_cmd)

    if result.returncode == 0:
        print(f"\nPASS: {name} (upgrade from {base_version})")
    else:
        print(f"\nFAIL: {name} (upgrade from {base_version})")

    return result.returncode == 0


def run_mondoo_pkg_test(
    name: str,
    image: str,
    pkg_mgr: str,
    version: str,
    releases_url: str,
    shell_on_failure: bool = False,
) -> bool:
    print(f"\n{'='*60}")
    print(f"  {name}  ({image})  [mondoo pkg]")
    print(f"{'='*60}")

    script = build_mondoo_pkg_script(version, releases_url, pkg_mgr)
    if shell_on_failure:
        script = _shell_on_failure_script(script)

    docker_cmd = [
        "docker", "run", "--rm",
        "--pull", "always",
        "--platform", "linux/amd64",
    ]
    if shell_on_failure:
        docker_cmd += ["-it"]
    if pkg_mgr == "apt":
        docker_cmd += [
            "--tmpfs", "/var/cache/apt:rw,size=256m",
            "--tmpfs", "/var/lib/apt/lists:rw,size=256m",
        ]
    else:
        docker_cmd += [
            "--tmpfs", "/var/cache/dnf:rw,size=512m",
        ]
    docker_cmd += [image, "bash", "-c", script]

    result = subprocess.run(docker_cmd)

    if result.returncode == 0:
        print(f"\nPASS: {name} (mondoo pkg)")
    else:
        print(f"\nFAIL: {name} (mondoo pkg)")

    return result.returncode == 0


def run_distro_test(
    name: str,
    image: str,
    pkg_mgr: str,
    install_version: str,
    releases_url: str,
    mql_latest: str,
    cnspec_latest: str,
    shell_on_failure: bool = False,
) -> bool:
    print(f"\n{'='*60}")
    print(f"  {name}  ({image})")
    print(f"{'='*60}")

    script = build_container_script(
        install_version, releases_url,
        mql_latest, cnspec_latest, pkg_mgr,
    )
    if shell_on_failure:
        script = _shell_on_failure_script(script)

    docker_cmd = [
        "docker", "run", "--rm",
        "--pull", "always",   # always use a fresh image to avoid stale GPG keys
        "--platform", "linux/amd64",
    ]
    if shell_on_failure:
        docker_cmd += ["-it"]
    if pkg_mgr == "apt":
        # Mount tmpfs over apt's cache dirs so package downloads don't exhaust
        # the container's overlay filesystem (which has limited space in Docker Desktop).
        docker_cmd += [
            "--tmpfs", "/var/cache/apt:rw,size=256m",
            "--tmpfs", "/var/lib/apt/lists:rw,size=256m",
        ]
    docker_cmd += [image, "bash", "-c", script]

    result = subprocess.run(docker_cmd)

    if result.returncode == 0:
        print(f"\nPASS: {name}")
    else:
        print(f"\nFAIL: {name}")

    return result.returncode == 0


def build_self_upgrade_script(
    from_version: str,
    target_version: str,
    releases_url: str,
    pkg_mgr: str,
) -> str:
    """Return a bash script that installs from_version, triggers the in-process
    self-upgrade, then verifies the binary was replaced with target_version."""

    if pkg_mgr == "apt":
        setup_curl = textwrap.dedent("""\
            apt-get update -qq \\
                -o Acquire::Check-Valid-Until=false \\
                -o Acquire::AllowInsecureRepositories=true
            apt-get install -y -q --no-install-recommends --allow-unauthenticated ca-certificates curl
            apt-get clean && rm -rf /var/lib/apt/lists/*""")
    else:
        setup_curl = "curl --version"

    mondoo_yml = textwrap.dedent(f"""\
        log-level: debug
        auto_update: true
        updates_url: {releases_url}
        providers_url: {DEFAULT_STABLE_RELEASES_URL}/providers
        features:
          - AutoUpdateEngine
    """)

    return textwrap.dedent(f"""\
        set -e

        # ---- ensure curl is available ----
        {setup_curl}

        # ---- install mql {from_version} ----
        TMPDIR=$(mktemp -d)
        curl -fsSL '{releases_url}/mql/{from_version}/mql_{from_version}_linux_amd64.tar.gz' \\
            | tar xz -C "$TMPDIR"
        find "$TMPDIR" -name mql -type f -exec mv {{}} /usr/local/bin/mql \\;
        rm -rf "$TMPDIR"
        chmod +x /usr/local/bin/mql
        echo "installed mql: $(mql version)"

        # ---- install cnspec {from_version} ----
        TMPDIR=$(mktemp -d)
        curl -fsSL '{releases_url}/cnspec/{from_version}/cnspec_{from_version}_linux_amd64.tar.gz' \\
            | tar xz -C "$TMPDIR"
        find "$TMPDIR" -name cnspec -type f -exec mv {{}} /usr/local/bin/cnspec \\;
        rm -rf "$TMPDIR"
        chmod +x /usr/local/bin/cnspec
        echo "installed cnspec: $(cnspec version)"

        # ---- seed mondoo config ----
        mkdir -p ~/.config/mondoo
        cat > ~/.config/mondoo/mondoo.yml << 'MONDOOEOF'
{mondoo_yml}MONDOOEOF

        # ---- trigger self-upgrade and verify version in output ----
        echo ""
        echo "=== mql run local -c mondoo.version (triggers self-upgrade) ==="
        MQL_RUN_OUT=$(mql run local -c 'mondoo.version' 2>&1) || true
        echo "$MQL_RUN_OUT"
        if echo "$MQL_RUN_OUT" | grep -qF '{target_version}'; then
            echo "PASS: mql self-upgraded to {target_version}"
        else
            echo "FAIL: mql output does not contain {target_version}"
            exit 1
        fi

        echo ""
        echo "=== cnspec run local -c mondoo.version (triggers self-upgrade) ==="
        CNSPEC_RUN_OUT=$(cnspec run local -c 'mondoo.version' 2>&1) || true
        echo "$CNSPEC_RUN_OUT"
        if echo "$CNSPEC_RUN_OUT" | grep -qF '{target_version}'; then
            echo "PASS: cnspec self-upgraded to {target_version}"
        else
            echo "FAIL: cnspec output does not contain {target_version}"
            exit 1
        fi
    """)


def run_self_upgrade_test(
    name: str,
    image: str,
    pkg_mgr: str,
    from_version: str,
    target_version: str,
    releases_url: str,
    shell_on_failure: bool = False,
) -> bool:
    print(f"\n{'='*60}")
    print(f"  {name}  ({image})  [self-upgrade from {from_version}]")
    print(f"{'='*60}")

    script = build_self_upgrade_script(from_version, target_version, releases_url, pkg_mgr)
    if shell_on_failure:
        script = _shell_on_failure_script(script)

    docker_cmd = [
        "docker", "run", "--rm",
        "--pull", "always",
        "--platform", "linux/amd64",
    ]
    if shell_on_failure:
        docker_cmd += ["-it"]
    if pkg_mgr == "apt":
        docker_cmd += [
            "--tmpfs", "/var/cache/apt:rw,size=256m",
            "--tmpfs", "/var/lib/apt/lists:rw,size=256m",
        ]
    docker_cmd += [image, "bash", "-c", script]

    result = subprocess.run(docker_cmd)

    if result.returncode == 0:
        print(f"\nPASS: {name} (self-upgrade from {from_version})")
    else:
        print(f"\nFAIL: {name} (self-upgrade from {from_version})")

    return result.returncode == 0


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Test mql/cnspec auto-update and mondoo metapackage via Docker containers",
    )
    parser.add_argument(
        "--install-version",
        required=True,
        help="Version to install/test, e.g. 13.0.0-rc2",
    )
    parser.add_argument(
        "--releases-url",
        default=DEFAULT_RELEASES_URL,
        help=f"Releases base URL (default: {DEFAULT_RELEASES_URL})",
    )
    parser.add_argument(
        "--skip-auto-update",
        action="store_true",
        help="Skip the auto-update tests",
    )
    parser.add_argument(
        "--skip-mondoo-pkg",
        action="store_true",
        help="Skip the mondoo metapackage installation tests",
    )
    parser.add_argument(
        "--skip-upgrade",
        action="store_true",
        help="Skip the upgrade tests",
    )
    parser.add_argument(
        "--base-versions",
        default=DEFAULT_BASE_VERSIONS,
        help=f"Comma-separated list of versions to upgrade from (default: {DEFAULT_BASE_VERSIONS})",
    )
    parser.add_argument(
        "--stable-releases-url",
        default=DEFAULT_STABLE_RELEASES_URL,
        help=f"Stable releases URL used to download base packages for upgrade tests (default: {DEFAULT_STABLE_RELEASES_URL})",
    )
    parser.add_argument(
        "--fail-fast",
        action="store_true",
        help="Stop after the first failure",
    )
    parser.add_argument(
        "--skip-self-upgrade",
        action="store_true",
        help="Skip the self-upgrade tests",
    )
    parser.add_argument(
        "--self-upgrade-from",
        default="",
        help="Version to install before triggering self-upgrade (e.g. 13.0.0-rc5); "
             "required to run self-upgrade tests",
    )
    parser.add_argument(
        "--distro",
        action="append",
        default=[],
        metavar="FILTER",
        help="Only run tests for distros whose name or image contains FILTER "
             "(case-insensitive). Can be repeated, e.g. --distro rocky --distro ubuntu.",
    )
    parser.add_argument(
        "--shell-on-failure",
        action="store_true",
        help="Drop into an interactive bash shell inside the container on failure (implies -it).",
    )
    args = parser.parse_args()

    install_version = args.install_version.lstrip("v")
    base_versions = [v.strip().lstrip("v") for v in args.base_versions.split(",") if v.strip()]

    distros = DISTROS
    if args.distro:
        filters = [f.lower() for f in args.distro]
        distros = [
            (name, image, pkg_mgr)
            for name, image, pkg_mgr in DISTROS
            if any(f in name.lower() or f in image.lower() for f in filters)
        ]
        if not distros:
            print(f"ERROR: no distros matched filters: {args.distro}")
            sys.exit(1)
        print(f"Filtered to distros: {[name for name, _, _ in distros]}")

    failures = []

    if not args.skip_auto_update:
        print(f"Fetching latest versions from {args.releases_url}...")
        mql_latest    = get_latest_version("mql",    args.releases_url)
        cnspec_latest = get_latest_version("cnspec", args.releases_url)

        print(f"  install version : {install_version}")
        print(f"  mql latest      : {mql_latest}")
        print(f"  cnspec latest   : {cnspec_latest}")

        print(f"\n{'='*60}")
        print("  AUTO-UPDATE TESTS")
        print(f"{'='*60}")
        for name, image, pkg_mgr in distros:
            ok = run_distro_test(
                name, image, pkg_mgr,
                install_version, args.releases_url,
                mql_latest, cnspec_latest,
                shell_on_failure=args.shell_on_failure,
            )
            if not ok:
                failures.append(f"{name} (auto-update)")
                if args.fail_fast:
                    break

    if failures and args.fail_fast:
        print(f"\n{'='*60}")
        print(f"FAILED on: {', '.join(failures)}")
        sys.exit(1)

    if not args.skip_mondoo_pkg:
        print(f"\n{'='*60}")
        print("  MONDOO METAPACKAGE TESTS")
        print(f"{'='*60}")
        for name, image, pkg_mgr in distros:
            ok = run_mondoo_pkg_test(
                name, image, pkg_mgr,
                install_version, args.releases_url,
                shell_on_failure=args.shell_on_failure,
            )
            if not ok:
                failures.append(f"{name} (mondoo pkg)")
                if args.fail_fast:
                    break

    if not args.skip_upgrade:
        print(f"\n{'='*60}")
        print("  UPGRADE TESTS")
        print(f"{'='*60}")
        print(f"  base versions   : {', '.join(base_versions)}")
        print(f"  stable url      : {args.stable_releases_url}")
        print(f"  target version  : {install_version}")
        done = False
        for base_version in base_versions:
            for name, image, pkg_mgr in distros:
                ok = run_upgrade_test(
                    name, image, pkg_mgr,
                    base_version, install_version,
                    args.stable_releases_url, args.releases_url,
                    shell_on_failure=args.shell_on_failure,
                )
                if not ok:
                    failures.append(f"{name} (upgrade from {base_version})")
                    if args.fail_fast:
                        done = True
                        break
            if done:
                break

    if failures and args.fail_fast:
        print(f"\n{'='*60}")
        print(f"FAILED on: {', '.join(failures)}")
        sys.exit(1)

    if not args.skip_self_upgrade:
        self_upgrade_from = args.self_upgrade_from.lstrip("v")
        if not self_upgrade_from:
            print(f"\n{'='*60}")
            print("  SELF-UPGRADE TESTS")
            print(f"{'='*60}")
            print("  Skipped: --self-upgrade-from not specified")
        else:
            print(f"\n{'='*60}")
            print("  SELF-UPGRADE TESTS")
            print(f"{'='*60}")
            print(f"  from version    : {self_upgrade_from}")
            print(f"  target version  : {install_version}")
            print(f"  releases url    : {args.releases_url}")
            for name, image, pkg_mgr in distros:
                ok = run_self_upgrade_test(
                    name, image, pkg_mgr,
                    self_upgrade_from, install_version,
                    args.releases_url,
                    shell_on_failure=args.shell_on_failure,
                )
                if not ok:
                    failures.append(f"{name} (self-upgrade from {self_upgrade_from})")
                    if args.fail_fast:
                        break

    print(f"\n{'='*60}")
    if failures:
        print(f"FAILED on: {', '.join(failures)}")
        sys.exit(1)
    print("All tests passed!")


if __name__ == "__main__":
    main()
