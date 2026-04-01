# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Auto-update tests."""

from __future__ import annotations

import pytest

from .distros import Distro
from .docker import DockerRunner
from .scripts import ScriptBuilder


@pytest.mark.auto_update
def test_auto_update(
    distro: Distro,
    install_version: str,
    releases_url: str,
    mql_latest: str,
    cnspec_latest: str,
    shell_on_failure: bool,
) -> None:
    """Test auto-update functionality for a distribution.

    Installs an older version, configures auto-update, and verifies
    that running mql/cnspec triggers an update to the latest version.
    """
    builder = ScriptBuilder(distro.pkg_mgr, releases_url)
    script = builder.build_auto_update_script(install_version, mql_latest, cnspec_latest)

    runner = DockerRunner(distro, shell_on_failure)
    assert runner.run(script), f"Auto-update test failed on {distro.name}"
