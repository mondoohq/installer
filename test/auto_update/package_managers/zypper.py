# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""SUSE zypper package manager implementation."""

from __future__ import annotations

import textwrap

from .base import PackageManager


class ZypperPackageManager(PackageManager):
    """SUSE zypper package manager."""

    @property
    def name(self) -> str:
        return "zypper"

    @property
    def pkg_extension(self) -> str:
        return "rpm"

    @property
    def docker_tmpfs_mounts(self) -> list[tuple[str, str]]:
        return [("/var/cache/zypp", "rw,size=512m")]

    def install_curl_script(self) -> str:
        return "zypper -n install curl"

    def install_packages_script(self, pkg_dir: str, packages: list[str]) -> str:
        pkg_paths = " ".join(f'"{pkg_dir}/{p}"' for p in packages)
        return f"zypper -n --no-gpg-checks install --allow-unsigned-rpm {pkg_paths}"

    def list_package_script(self, package: str) -> str:
        return f"rpm -q {package}"

    def check_package_removed_script(self, package: str) -> str:
        return textwrap.dedent(f"""\
            if rpm -q {package} >/dev/null 2>&1; then
                echo "FAIL: {package} should have been removed but is still installed"
                exit 1
            else
                echo "PASS: {package} was properly replaced by mql"
            fi""")
