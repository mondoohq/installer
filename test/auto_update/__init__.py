# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""
Auto-update test suite for mql/cnspec.

This package tests:
  - Auto-update functionality via tarball installation
  - Mondoo metapackage installation from .deb/.rpm/.pkg.tar.zst packages
  - Upgrade from v11/v12 (cnquery) to v13+ (mql)
  - Self-upgrade via the in-process auto-update engine

Supported distros:
  - DEB-based: Debian 11/12, Ubuntu 20.04/22.04/24.04
  - RPM-based (dnf): AlmaLinux 9, Rocky Linux 8/9, CentOS Stream 9, Oracle Linux 8/9
  - RPM-based (zypper): SUSE SLE 15.6
  - Pacman-based: Arch Linux

Usage:
    python -m auto_update --install-version 13.0.0
    python -m auto_update --install-version 13.0.0 --distro arch
    python -m auto_update --install-version 13.0.0 --skip-upgrade --skip-self-upgrade
"""

from .cli import main
from .constants import (
    DEFAULT_BASE_VERSIONS,
    DEFAULT_RELEASES_URL,
    DEFAULT_STABLE_RELEASES_URL,
)
from .distros import DISTROS, Distro, filter_distros
from .docker import DockerRunner
from .package_managers import PACKAGE_MANAGERS, PackageManager
from .scripts import ScriptBuilder

__all__ = [
    "main",
    "DISTROS",
    "Distro",
    "filter_distros",
    "DockerRunner",
    "ScriptBuilder",
    "PackageManager",
    "PACKAGE_MANAGERS",
    "DEFAULT_RELEASES_URL",
    "DEFAULT_STABLE_RELEASES_URL",
    "DEFAULT_BASE_VERSIONS",
]
