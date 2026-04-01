# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Utility functions for auto-update tests."""

from __future__ import annotations

import json
import urllib.request
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .distros import Distro


def get_latest_version(product: str, releases_url: str) -> str:
    """Fetch the latest version of a product from the releases API."""
    url = f"{releases_url}/{product}/latest.json"
    with urllib.request.urlopen(url) as resp:
        return json.load(resp)["version"]


def print_header(title: str) -> None:
    """Print a section header."""
    print(f"\n{'=' * 60}")
    print(f"  {title}")
    print(f"{'=' * 60}")


def print_test_header(distro: Distro, suffix: str = "") -> None:
    """Print a test header for a specific distro."""
    print(f"\n{'=' * 60}")
    label = f"  {distro.name}  ({distro.image})"
    if suffix:
        label += f"  [{suffix}]"
    print(label)
    print(f"{'=' * 60}")
