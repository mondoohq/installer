# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

"""
Test auto-update of mql and cnspec using Docker containers.

Spins up RPM- and DEB-based containers, installs a given version of
cnspec and mql from releases.mondoo.love, seeds ~/.config/mondoo/mondoo.yml
with auto-update configuration, then runs:

    mql run local -c 'mondoo'
    cnspec run local -c 'mondoo'

and verifies the output contains the latest version as reported by
https://releases.mondoo.love/{product}/latest.json.

Usage:
    python3 test_auto_update.py --install-version 13.0.0-rc2
    python3 test_auto_update.py --install-version 13.0.0-rc2 --releases-url https://releases.mondoo.love
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

    # providers_url is deprecated in cnspec v13; updates_url covers both binary
    # and provider updates.  Since releases.mondoo.love does not host providers,
    # omit providers_url entirely so that a 404 is handled gracefully rather than
    # producing a fatal JSON-parse error on a format-mismatched response.
    mondoo_yml = textwrap.dedent(f"""\
        log-level: debug
        auto_update: true
        updates_url: {releases_url}
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
        echo "=== mql run local -c 'mondoo' ==="
        MQL_OUT=$(mql run local -c 'mondoo' 2>&1) || true
        echo "$MQL_OUT"
        if echo "$MQL_OUT" | grep -qF '{mql_latest}'; then
            echo "PASS: mql output contains version {mql_latest}"
        else
            echo "FAIL: mql output does not contain version {mql_latest}"
            exit 1
        fi

        # ---- run cnspec and verify version ----
        echo ""
        echo "=== cnspec run local -c 'mondoo' ==="
        CNSPEC_OUT=$(cnspec run local -c 'mondoo' 2>&1) || true
        echo "$CNSPEC_OUT"
        if echo "$CNSPEC_OUT" | grep -qF '{cnspec_latest}'; then
            echo "PASS: cnspec output contains version {cnspec_latest}"
        else
            echo "FAIL: cnspec output does not contain version {cnspec_latest}"
            exit 1
        fi
    """)


def run_distro_test(
    name: str,
    image: str,
    pkg_mgr: str,
    install_version: str,
    releases_url: str,
    mql_latest: str,
    cnspec_latest: str,
) -> bool:
    print(f"\n{'='*60}")
    print(f"  {name}  ({image})")
    print(f"{'='*60}")

    script = build_container_script(
        install_version, releases_url,
        mql_latest, cnspec_latest, pkg_mgr,
    )

    docker_cmd = [
        "docker", "run", "--rm",
        "--pull", "always",   # always use a fresh image to avoid stale GPG keys
        "--platform", "linux/amd64",
    ]
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


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Test mql/cnspec auto-update via Docker containers",
    )
    parser.add_argument(
        "--install-version",
        required=True,
        help="Version to install initially, e.g. 13.0.0-rc2",
    )
    parser.add_argument(
        "--releases-url",
        default=DEFAULT_RELEASES_URL,
        help=f"Releases base URL (default: {DEFAULT_RELEASES_URL})",
    )
    args = parser.parse_args()

    install_version = args.install_version.lstrip("v")

    print(f"Fetching latest versions from {args.releases_url}...")
    mql_latest    = get_latest_version("mql",    args.releases_url)
    cnspec_latest = get_latest_version("cnspec", args.releases_url)

    print(f"  install version : {install_version}")
    print(f"  mql latest      : {mql_latest}")
    print(f"  cnspec latest   : {cnspec_latest}")

    failures = []
    for name, image, pkg_mgr in DISTROS:
        ok = run_distro_test(
            name, image, pkg_mgr,
            install_version, args.releases_url,
            mql_latest, cnspec_latest,
        )
        if not ok:
            failures.append(name)

    print(f"\n{'='*60}")
    if failures:
        print(f"FAILED on: {', '.join(failures)}")
        sys.exit(1)
    print("All tests passed!")


if __name__ == "__main__":
    main()
