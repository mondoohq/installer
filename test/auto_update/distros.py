# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Linux distribution definitions for testing."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from .package_managers import PACKAGE_MANAGERS, PackageManager

if TYPE_CHECKING:
    from collections.abc import Sequence


@dataclass(frozen=True)
class Distro:
    """Represents a Linux distribution to test."""

    name: str
    image: str
    pkg_mgr_name: str

    @property
    def pkg_mgr(self) -> PackageManager:
        return PACKAGE_MANAGERS[self.pkg_mgr_name]

    def matches_filter(self, filters: Sequence[str]) -> bool:
        """Check if this distro matches any of the given filters."""
        name_lower = self.name.lower()
        image_lower = self.image.lower()
        return any(f in name_lower or f in image_lower for f in filters)


def filter_distros(distros: list[Distro], filters: Sequence[str]) -> list[Distro]:
    """Filter distros by name/image matching."""
    lower_filters = [f.lower() for f in filters]
    return [d for d in distros if d.matches_filter(lower_filters)]


# All supported distros
DISTROS = [
    # DEB-based
    Distro("Debian 11", "debian:11", "apt"),
    Distro("Debian 12", "debian:12", "apt"),
    Distro("Debian 13", "debian:13", "apt"),
    Distro("Ubuntu 20.04", "ubuntu:20.04", "apt"),
    Distro("Ubuntu 22.04", "ubuntu:22.04", "apt"),
    Distro("Ubuntu 24.04", "ubuntu:24.04", "apt"),
    # RPM-based (dnf)
    Distro("AlmaLinux 9", "almalinux:9", "dnf"),
    Distro("Rocky Linux 8", "rockylinux:8", "dnf"),
    Distro("Rocky Linux 9", "rockylinux:9", "dnf"),
    Distro("CentOS Stream 9", "quay.io/centos/centos:stream9", "dnf"),
    Distro("Oracle Linux 8", "oraclelinux:8", "dnf"),
    Distro("Oracle Linux 9", "oraclelinux:9", "dnf"),
    # RPM-based (zypper)
    Distro("SUSE SLE 15.6", "registry.suse.com/suse/sle15:15.6", "zypper"),
    # Pacman-based
    Distro("Arch Linux", "archlinux:latest", "pacman"),
]
