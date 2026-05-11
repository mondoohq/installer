# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Mondoo metapackage installation tests."""

from __future__ import annotations

import pytest

from .distros import Distro
from .docker import DockerRunner
from .scripts import ScriptBuilder


@pytest.mark.mondoo_pkg
def test_mondoo_pkg(
    distro: Distro,
    install_version: str,
    releases_url: str,
    shell_on_failure: bool,
) -> None:
    """Test mondoo metapackage installation.

    Downloads and installs mql, cnspec, and mondoo packages, then
    verifies the correct versions are installed.
    """
    builder = ScriptBuilder(distro.pkg_mgr, releases_url)
    script = builder.build_mondoo_pkg_script(install_version)

    runner = DockerRunner(distro, shell_on_failure)
    assert runner.run(script), f"Mondoo metapackage test failed on {distro.name}"
