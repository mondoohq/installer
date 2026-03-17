# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Arch Linux pacman package manager implementation."""

from __future__ import annotations

import textwrap

from .base import PackageManager


class PacmanPackageManager(PackageManager):
    """Arch Linux pacman package manager."""

    @property
    def name(self) -> str:
        return "pacman"

    @property
    def pkg_extension(self) -> str:
        return "pkg.tar.zst"

    @property
    def docker_tmpfs_mounts(self) -> list[tuple[str, str]]:
        return [("/var/cache/pacman/pkg", "rw,size=512m")]

    def install_curl_script(self) -> str:
        # Arch needs system update first, then curl and build deps for AUR
        # Disable pacman's internal sandbox which fails in Docker
        return textwrap.dedent("""\
            echo 'DisableSandbox' >> /etc/pacman.conf
            pacman -Syu --noconfirm
            pacman -S --noconfirm curl base-devel git
            useradd -m test
            echo "test ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers""")

    def install_packages_script(self, pkg_dir: str, packages: list[str]) -> str:
        pkg_paths = " ".join(f'"{pkg_dir}/{p}"' for p in packages)
        return f"pacman -U --noconfirm {pkg_paths}"

    def list_package_script(self, package: str) -> str:
        return f"pacman -Q {package}"

    def check_package_removed_script(self, package: str) -> str:
        return textwrap.dedent(f"""\
            if pacman -Q {package} >/dev/null 2>&1; then
                echo "FAIL: {package} should have been removed but is still installed"
                exit 1
            else
                echo "PASS: {package} was properly replaced by mql"
            fi""")

    def install_from_aur_script(self, package: str) -> str:
        """Install a package from AUR using makepkg."""
        return textwrap.dedent(f"""\
            cd /tmp
            su test -c "git clone https://aur.archlinux.org/{package} && cd {package} && makepkg"
            cd {package} && pacman -U --noconfirm {package}-*.zst
            echo "installed {package}: $({package} version)"
            cd /tmp""")
