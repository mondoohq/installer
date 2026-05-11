# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Abstract base class for package manager implementations."""

from __future__ import annotations

import textwrap
from abc import ABC, abstractmethod


class PackageManager(ABC):
    """Abstract base class for package manager implementations."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Return the package manager name (apt, dnf, zypper, pacman)."""

    @property
    @abstractmethod
    def pkg_extension(self) -> str:
        """Return the package file extension (deb, rpm, pkg.tar.zst)."""

    @property
    @abstractmethod
    def docker_tmpfs_mounts(self) -> list[tuple[str, str]]:
        """Return list of (path, options) tuples for tmpfs mounts."""

    @abstractmethod
    def install_curl_script(self) -> str:
        """Return bash commands to ensure curl is available."""

    @abstractmethod
    def install_packages_script(self, pkg_dir: str, packages: list[str]) -> str:
        """Return bash commands to install packages from pkg_dir."""

    @abstractmethod
    def list_package_script(self, package: str) -> str:
        """Return bash commands to list/verify a package is installed."""

    @abstractmethod
    def check_package_removed_script(self, package: str) -> str:
        """Return bash commands that exit 0 if package is removed, 1 if installed."""

    def install_from_aur_script(self, package: str) -> str:
        """Return bash commands to install a package from AUR. Only implemented for pacman."""
        raise NotImplementedError(f"{self.name} does not support AUR installation")
