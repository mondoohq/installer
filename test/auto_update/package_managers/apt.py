# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Debian/Ubuntu apt package manager implementation."""

from __future__ import annotations

import textwrap

from .base import PackageManager


class AptPackageManager(PackageManager):
    """Debian/Ubuntu apt package manager."""

    @property
    def name(self) -> str:
        return "apt"

    @property
    def pkg_extension(self) -> str:
        return "deb"

    @property
    def docker_tmpfs_mounts(self) -> list[tuple[str, str]]:
        return [
            ("/var/cache/apt", "rw,size=256m"),
            ("/var/lib/apt/lists", "rw,size=256m"),
        ]

    def install_curl_script(self) -> str:
        return textwrap.dedent("""\
            apt-get update -qq \\
                -o Acquire::Check-Valid-Until=false \\
                -o Acquire::AllowInsecureRepositories=true
            apt-get install -y -q --no-install-recommends --allow-unauthenticated ca-certificates curl
            apt-get clean && rm -rf /var/lib/apt/lists/*""")

    def install_packages_script(self, pkg_dir: str, packages: list[str]) -> str:
        pkg_paths = " ".join(f'"{pkg_dir}/{p}"' for p in packages)
        return f"apt install -y {pkg_paths}"

    def list_package_script(self, package: str) -> str:
        return f"dpkg -l {package}"

    def check_package_removed_script(self, package: str) -> str:
        return textwrap.dedent(f"""\
            if dpkg -l 2>/dev/null | awk '/^ii/{{print $2}}' | grep -qx '{package}'; then
                echo "FAIL: {package} should have been removed but is still installed"
                exit 1
            else
                echo "PASS: {package} was properly replaced by mql"
            fi""")
