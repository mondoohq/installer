# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""AUR installation tests (Arch Linux only)."""

from __future__ import annotations

import pytest

from .distros import Distro
from .docker import DockerRunner
from .scripts import ScriptBuilder


@pytest.mark.aur
@pytest.mark.pacman
def test_aur_mql_makepkg(
    distro: Distro,
    install_version: str,
    releases_url: str,
    shell_on_failure: bool,
) -> None:
    """Test mql installation from AUR via makepkg."""
    builder = ScriptBuilder(distro.pkg_mgr, releases_url)
    script = builder.build_aur_mql_install_script(install_version)

    runner = DockerRunner(distro, shell_on_failure)
    assert runner.run(script), f"AUR mql makepkg test failed on {distro.name}"


@pytest.mark.aur
@pytest.mark.pacman
def test_aur_cnspec_yay(
    distro: Distro,
    install_version: str,
    releases_url: str,
    shell_on_failure: bool,
) -> None:
    """Test cnspec installation from AUR via yay (also installs mql as dependency)."""
    builder = ScriptBuilder(distro.pkg_mgr, releases_url)
    script = builder.build_aur_cnspec_yay_script(install_version)

    runner = DockerRunner(distro, shell_on_failure)
    assert runner.run(script), f"AUR cnspec yay test failed on {distro.name}"
