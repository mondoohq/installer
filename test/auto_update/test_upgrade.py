# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Upgrade tests (cnquery -> mql)."""

from __future__ import annotations

import pytest

from .distros import Distro
from .docker import DockerRunner
from .scripts import ScriptBuilder


@pytest.mark.upgrade
def test_upgrade(
    distro: Distro,
    base_version: str,
    install_version: str,
    stable_releases_url: str,
    releases_url: str,
    shell_on_failure: bool,
) -> None:
    """Test upgrade from cnquery (v11/v12) to mql (v13+).

    Installs a base version, then upgrades to the target version
    and verifies the old package was replaced.
    """
    # Skip Arch Linux - tested separately with AUR
    if distro.pkg_mgr_name == "pacman":
        pytest.skip("Arch Linux upgrade tested separately with AUR")

    builder = ScriptBuilder(distro.pkg_mgr, releases_url)
    script = builder.build_upgrade_script(base_version, install_version, stable_releases_url)

    runner = DockerRunner(distro, shell_on_failure)
    assert runner.run(script), f"Upgrade test failed on {distro.name} (from {base_version})"


@pytest.mark.upgrade
@pytest.mark.aur
@pytest.mark.pacman
def test_aur_upgrade(
    distro: Distro,
    install_version: str,
    releases_url: str,
    shell_on_failure: bool,
) -> None:
    """Test AUR upgrade from cnquery to mql (Arch Linux only).

    Installs cnquery from AUR, removes it, and installs mql.
    """
    builder = ScriptBuilder(distro.pkg_mgr, releases_url)
    script = builder.build_aur_upgrade_script(install_version)

    runner = DockerRunner(distro, shell_on_failure)
    assert runner.run(script), f"AUR upgrade test failed on {distro.name}"


@pytest.mark.self_upgrade
def test_self_upgrade(
    distro: Distro,
    self_upgrade_from: str,
    install_version: str,
    releases_url: str,
    shell_on_failure: bool,
) -> None:
    """Test self-upgrade functionality.

    Installs an older version, then verifies that running mql/cnspec
    triggers a self-upgrade to the target version.
    """
    if not self_upgrade_from:
        pytest.skip("--self-upgrade-from not specified")

    builder = ScriptBuilder(distro.pkg_mgr, releases_url)
    script = builder.build_self_upgrade_script(self_upgrade_from, install_version)

    runner = DockerRunner(distro, shell_on_failure)
    assert runner.run(script), f"Self-upgrade test failed on {distro.name}"
