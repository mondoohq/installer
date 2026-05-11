# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""install.sh tests (fresh install and upgrade)."""

from __future__ import annotations

import pytest

from .distros import Distro
from .docker import DockerRunner
from .scripts import ScriptBuilder


@pytest.mark.install_sh
def test_install_sh_fresh_install(
    distro: Distro,
    package: str,
    install_version: str,
    shell_on_failure: bool,
    use_local_install_sh: bool,
) -> None:
    """Test fresh install via install.sh (curl | bash).

    Installs a package (cnspec or mql) via install.sh and verifies the
    expected version is installed.
    """
    builder = ScriptBuilder(distro.pkg_mgr, "")
    script = builder.build_install_sh_fresh_install_script(
        package,
        install_version,
        use_local=use_local_install_sh,
    )

    runner = DockerRunner(distro, shell_on_failure)
    assert runner.run(script, mount_workdir=use_local_install_sh), \
        f"install.sh fresh install of {package} failed on {distro.name}"


@pytest.mark.install_sh
def test_install_sh_upgrade(
    distro: Distro,
    install_sh_upgrade_from: str,
    install_version: str,
    stable_releases_url: str,
    releases_url: str,
    shell_on_failure: bool,
    use_local_install_sh: bool,
) -> None:
    """Test upgrade via install.sh.

    Installs cnquery from releases.mondoo.com, then upgrades to mql
    via install.sh (either local or from install.mondoo.com).
    """
    if not install_sh_upgrade_from:
        pytest.skip("--install-sh-upgrade-from not specified")

    builder = ScriptBuilder(distro.pkg_mgr, releases_url)
    script = builder.build_install_sh_upgrade_script(
        install_sh_upgrade_from,
        install_version,
        stable_releases_url,
        use_local=use_local_install_sh,
    )

    runner = DockerRunner(distro, shell_on_failure)
    assert runner.run(script, mount_workdir=use_local_install_sh), \
        f"install.sh upgrade test failed on {distro.name}"
