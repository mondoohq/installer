# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Package manager implementations for different Linux distributions."""

from .apt import AptPackageManager
from .base import PackageManager
from .dnf import DnfPackageManager
from .pacman import PacmanPackageManager
from .zypper import ZypperPackageManager

# Package manager registry
PACKAGE_MANAGERS: dict[str, PackageManager] = {
    "apt": AptPackageManager(),
    "dnf": DnfPackageManager(),
    "zypper": ZypperPackageManager(),
    "pacman": PacmanPackageManager(),
}

__all__ = [
    "PackageManager",
    "AptPackageManager",
    "DnfPackageManager",
    "ZypperPackageManager",
    "PacmanPackageManager",
    "PACKAGE_MANAGERS",
]
