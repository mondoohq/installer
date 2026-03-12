# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Pytest configuration and fixtures for auto-update tests."""

from __future__ import annotations

import pytest

from .constants import (
    DEFAULT_BASE_VERSIONS,
    DEFAULT_RELEASES_URL,
    DEFAULT_STABLE_RELEASES_URL,
)
from .distros import DISTROS, Distro, filter_distros
from .utils import get_latest_version


def pytest_addoption(parser: pytest.Parser) -> None:
    """Add custom command-line options."""
    parser.addoption(
        "--install-version",
        required=True,
        help="Version to install/test, e.g. 13.0.0-rc2",
    )
    parser.addoption(
        "--releases-url",
        default=DEFAULT_RELEASES_URL,
        help=f"Releases base URL (default: {DEFAULT_RELEASES_URL})",
    )
    parser.addoption(
        "--stable-releases-url",
        default=DEFAULT_STABLE_RELEASES_URL,
        help=f"Stable releases URL (default: {DEFAULT_STABLE_RELEASES_URL})",
    )
    parser.addoption(
        "--base-versions",
        default=DEFAULT_BASE_VERSIONS,
        help=f"Comma-separated versions to upgrade from (default: {DEFAULT_BASE_VERSIONS})",
    )
    parser.addoption(
        "--self-upgrade-from",
        default="",
        help="Version to install before triggering self-upgrade (e.g. 13.0.0-rc5)",
    )
    parser.addoption(
        "--install-sh-upgrade-from",
        default="",
        help="Version to install before upgrading via install.sh (e.g. 12.0.0)",
    )
    parser.addoption(
        "--distro",
        action="append",
        default=[],
        dest="distro_filters",
        metavar="FILTER",
        help="Only run tests for distros matching FILTER (case-insensitive). Can be repeated.",
    )
    parser.addoption(
        "--shell-on-failure",
        action="store_true",
        help="Drop into an interactive bash shell inside the container on failure.",
    )
    parser.addoption(
        "--use-local-install-sh",
        action="store_true",
        help="Use local install.sh instead of downloading from install.mondoo.com",
    )


def pytest_configure(config: pytest.Config) -> None:
    """Register custom markers."""
    config.addinivalue_line("markers", "auto_update: auto-update tests")
    config.addinivalue_line("markers", "mondoo_pkg: mondoo metapackage tests")
    config.addinivalue_line("markers", "upgrade: upgrade tests (cnquery -> mql)")
    config.addinivalue_line("markers", "self_upgrade: self-upgrade tests")
    config.addinivalue_line("markers", "install_sh: install.sh upgrade tests")
    config.addinivalue_line("markers", "aur: AUR installation tests (Arch Linux)")
    config.addinivalue_line("markers", "apt: tests for apt-based distros")
    config.addinivalue_line("markers", "dnf: tests for dnf-based distros")
    config.addinivalue_line("markers", "zypper: tests for zypper-based distros")
    config.addinivalue_line("markers", "pacman: tests for pacman-based distros (Arch)")


@pytest.fixture(scope="session")
def install_version(request: pytest.FixtureRequest) -> str:
    """Get the target version to install."""
    return request.config.getoption("--install-version").lstrip("v")


@pytest.fixture(scope="session")
def releases_url(request: pytest.FixtureRequest) -> str:
    """Get the releases URL."""
    return request.config.getoption("--releases-url")


@pytest.fixture(scope="session")
def stable_releases_url(request: pytest.FixtureRequest) -> str:
    """Get the stable releases URL."""
    return request.config.getoption("--stable-releases-url")


@pytest.fixture(scope="session")
def base_versions(request: pytest.FixtureRequest) -> list[str]:
    """Get the base versions for upgrade tests."""
    versions_str = request.config.getoption("--base-versions")
    return [v.strip().lstrip("v") for v in versions_str.split(",") if v.strip()]


@pytest.fixture(scope="session")
def self_upgrade_from(request: pytest.FixtureRequest) -> str:
    """Get the version for self-upgrade tests."""
    return request.config.getoption("--self-upgrade-from").lstrip("v")


@pytest.fixture(scope="session")
def install_sh_upgrade_from(request: pytest.FixtureRequest) -> str:
    """Get the version for install.sh upgrade tests."""
    return request.config.getoption("--install-sh-upgrade-from").lstrip("v")


@pytest.fixture(scope="session")
def shell_on_failure(request: pytest.FixtureRequest) -> bool:
    """Check if shell-on-failure mode is enabled."""
    return request.config.getoption("--shell-on-failure")


@pytest.fixture(scope="session")
def use_local_install_sh(request: pytest.FixtureRequest) -> bool:
    """Check if local install.sh should be used."""
    return request.config.getoption("--use-local-install-sh")


@pytest.fixture(scope="session")
def distro_filters(request: pytest.FixtureRequest) -> list[str]:
    """Get the distro filters."""
    return request.config.getoption("--distro") or []


@pytest.fixture(scope="session")
def mql_latest(releases_url: str) -> str:
    """Fetch the latest mql version."""
    return get_latest_version("mql", releases_url)


@pytest.fixture(scope="session")
def cnspec_latest(releases_url: str) -> str:
    """Fetch the latest cnspec version."""
    return get_latest_version("cnspec", releases_url)


def get_filtered_distros(distro_filters: list[str]) -> list[Distro]:
    """Get distros filtered by command-line options."""
    if distro_filters:
        return filter_distros(DISTROS, distro_filters)
    return DISTROS


def pytest_generate_tests(metafunc: pytest.Metafunc) -> None:
    """Generate test parameters for distro-based tests."""
    distro_filters = metafunc.config.getoption("--distro") or []
    distros = get_filtered_distros(distro_filters)

    # Parametrize based on fixture names in the test
    if "distro" in metafunc.fixturenames:
        # Filter based on test markers
        markers = list(metafunc.definition.iter_markers())
        marker_names = {m.name for m in markers}

        filtered_distros = distros
        if "apt" in marker_names:
            filtered_distros = [d for d in distros if d.pkg_mgr_name == "apt"]
        elif "dnf" in marker_names:
            filtered_distros = [d for d in distros if d.pkg_mgr_name == "dnf"]
        elif "zypper" in marker_names:
            filtered_distros = [d for d in distros if d.pkg_mgr_name == "zypper"]
        elif "pacman" in marker_names or "aur" in marker_names:
            filtered_distros = [d for d in distros if d.pkg_mgr_name == "pacman"]
        elif "mondoo_pkg" in marker_names:
            # mondoo-pkg tests skip Arch (AUR packages tested separately)
            filtered_distros = [d for d in distros if d.pkg_mgr_name != "pacman"]
        elif "install_sh" in marker_names:
            # install.sh doesn't support pacman
            filtered_distros = [d for d in distros if d.pkg_mgr_name != "pacman"]

        metafunc.parametrize(
            "distro",
            filtered_distros,
            ids=[d.name for d in filtered_distros],
        )

    if "base_version" in metafunc.fixturenames:
        base_versions_str = metafunc.config.getoption("--base-versions")
        versions = [v.strip().lstrip("v") for v in base_versions_str.split(",") if v.strip()]
        metafunc.parametrize("base_version", versions)
