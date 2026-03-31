# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Bash script builders for test scenarios."""

from __future__ import annotations

import textwrap
from typing import TYPE_CHECKING

from .constants import DEFAULT_STABLE_RELEASES_URL

if TYPE_CHECKING:
    from .package_managers import PackageManager


def _mql_product(version: str) -> str:
    """Return 'cnquery' for v11/v12 (before the cnquery→mql rename), 'mql' for v13+."""
    major = int(version.split(".")[0])
    return "cnquery" if major < 13 else "mql"


class ScriptBuilder:
    """Builds bash scripts for various test scenarios."""

    def __init__(self, pkg_mgr: PackageManager, releases_url: str):
        self.pkg_mgr = pkg_mgr
        self.releases_url = releases_url

    def _download_tarball(self, product: str, version: str, dest_dir: str) -> str:
        """Generate script to download and extract a tarball."""
        url = f"{self.releases_url}/{product}/{version}/{product}_{version}_linux_amd64.tar.gz"
        return textwrap.dedent(f"""\
            TMPDIR=$(mktemp -d)
            curl -fsSL '{url}' | tar xz -C "$TMPDIR"
            find "$TMPDIR" -name {product} -type f -exec mv {{}} {dest_dir}/{product} \\;
            rm -rf "$TMPDIR"
            chmod +x {dest_dir}/{product}
            echo "installed {product}: $({dest_dir}/{product} version)"
        """)

    def _download_package(self, product: str, version: str, url_base: str, pkg_dir: str) -> str:
        """Generate script to download a package file."""
        ext = self.pkg_mgr.pkg_extension
        url = f"{url_base}/{product}/{version}/{product}_{version}_linux_amd64.{ext}"
        return f"curl -fsSL '{url}' -o \"{pkg_dir}/{product}.{ext}\""

    def _verify_version(self, binary: str, expected_version: str) -> str:
        """Generate script to verify a binary's version."""
        var_name = binary.upper().replace("-", "_") + "_OUT"
        return textwrap.dedent(f"""\
            echo ""
            echo "=== {binary} version ==="
            {var_name}=$({binary} version 2>&1)
            echo "${var_name}"
            if echo "${var_name}" | grep -qF '{expected_version}'; then
                echo "PASS: {binary} version contains {expected_version}"
            else
                echo "FAIL: {binary} version does not contain {expected_version}"
                exit 1
            fi
        """)

    def _mondoo_config(self) -> str:
        """Generate mondoo.yml content for auto-update tests."""
        return textwrap.dedent(f"""\
            log-level: debug
            auto_update: true
            updates_url: {self.releases_url}
            providers_url: {DEFAULT_STABLE_RELEASES_URL}/providers
            features:
              - AutoUpdateEngine
        """)

    def build_auto_update_script(
        self,
        install_version: str,
        mql_latest: str,
        cnspec_latest: str,
    ) -> str:
        """Build script for auto-update test."""
        mondoo_yml = self._mondoo_config()

        return textwrap.dedent(f"""\
            set -e

            # ---- ensure curl is available ----
            {self.pkg_mgr.install_curl_script()}

            # ---- install mql {install_version} ----
            {self._download_tarball("mql", install_version, "/usr/local/bin")}

            # ---- install cnspec {install_version} ----
            {self._download_tarball("cnspec", install_version, "/usr/local/bin")}

            # ---- seed mondoo config ----
            mkdir -p ~/.config/mondoo
            cat > ~/.config/mondoo/mondoo.yml << 'MONDOOEOF'
            {mondoo_yml}MONDOOEOF

            # ---- run mql and verify version ----
            echo ""
            echo "=== mql run local -c mondoo.version ==="
            MQL_OUT=$(mql run local -c "mondoo.version" 2>&1) || true
            echo "$MQL_OUT"
            if echo "$MQL_OUT" | grep -qF '{mql_latest}'; then
                echo "PASS: mql output contains version {mql_latest}"
            else
                echo "FAIL: mql output does not contain version {mql_latest}"
                exit 1
            fi

            # ---- run cnspec and verify version ----
            echo ""
            echo "=== cnspec run local -c mondoo.version ==="
            CNSPEC_OUT=$(cnspec run local -c "mondoo.version" 2>&1) || true
            echo "$CNSPEC_OUT"
            if echo "$CNSPEC_OUT" | grep -qF '{cnspec_latest}'; then
                echo "PASS: cnspec output contains version {cnspec_latest}"
            else
                echo "FAIL: cnspec output does not contain version {cnspec_latest}"
                exit 1
            fi
        """)

    def build_mondoo_pkg_script(self, version: str) -> str:
        """Build script for mondoo metapackage installation test."""
        ext = self.pkg_mgr.pkg_extension
        packages = [f"mql.{ext}", f"cnspec.{ext}", f"mondoo.{ext}"]

        return textwrap.dedent(f"""\
            set -e

            # ---- setup and install packages ----
            {self.pkg_mgr.install_curl_script()}

            PKGDIR=$(mktemp -d)
            {self._download_package("mql", version, self.releases_url, "$PKGDIR")}
            {self._download_package("cnspec", version, self.releases_url, "$PKGDIR")}
            {self._download_package("mondoo", version, self.releases_url, "$PKGDIR")}
            {self.pkg_mgr.install_packages_script("$PKGDIR", packages)}
            rm -rf "$PKGDIR"

            echo "--- {self.pkg_mgr.list_package_script('mondoo')} ---"
            {self.pkg_mgr.list_package_script("mondoo")}

            {self._verify_version("mql", version)}
            {self._verify_version("cnspec", version)}
        """)

    def _install_base_version_script(self, base_version: str, stable_url: str) -> str:
        """Generate script to install base version packages from releases."""
        base_product = _mql_product(base_version)
        ext = self.pkg_mgr.pkg_extension
        base_packages = [f"base-mql.{ext}", f"cnspec.{ext}", f"mondoo.{ext}"]

        return textwrap.dedent(f"""\
            # ---- install base version {base_version} ({base_product}) ----
            echo "Installing base version {base_version}..."
            PKGDIR=$(mktemp -d)
            curl -fsSL '{stable_url}/{base_product}/{base_version}/{base_product}_{base_version}_linux_amd64.{ext}' -o "$PKGDIR/base-mql.{ext}"
            {self._download_package("cnspec", base_version, stable_url, "$PKGDIR")}
            {self._download_package("mondoo", base_version, stable_url, "$PKGDIR")}
            {self.pkg_mgr.install_packages_script("$PKGDIR", base_packages)}
            rm -rf "$PKGDIR"
            echo "base {base_product}: $({base_product} version)"
            echo "base cnspec:         $(cnspec version)"
        """)

    def build_upgrade_script(
        self,
        base_version: str,
        target_version: str,
        stable_url: str,
    ) -> str:
        """Build script for upgrade test (from v11/v12 cnquery to v13+ mql)."""
        base_product = _mql_product(base_version)
        ext = self.pkg_mgr.pkg_extension
        target_packages = [f"mql.{ext}", f"cnspec.{ext}", f"mondoo.{ext}"]

        return textwrap.dedent(f"""\
            set -e

            # ---- setup ----
            {self.pkg_mgr.install_curl_script()}

            {self._install_base_version_script(base_version, stable_url)}

            # ---- upgrade to {target_version} ----
            echo ""
            echo "Upgrading to {target_version}..."
            PKGDIR=$(mktemp -d)
            {self._download_package("mql", target_version, self.releases_url, "$PKGDIR")}
            {self._download_package("cnspec", target_version, self.releases_url, "$PKGDIR")}
            {self._download_package("mondoo", target_version, self.releases_url, "$PKGDIR")}
            {self.pkg_mgr.install_packages_script("$PKGDIR", target_packages)}
            rm -rf "$PKGDIR"

            echo "--- {self.pkg_mgr.list_package_script('mondoo')} ---"
            {self.pkg_mgr.list_package_script("mondoo")}

            {self._verify_version("mql", target_version)}
            {self._verify_version("cnspec", target_version)}

            # ---- verify {base_product} was removed ----
            echo ""
            echo "=== Verifying {base_product} was removed ==="
            {self.pkg_mgr.check_package_removed_script(base_product)}
        """)

    def build_install_sh_fresh_install_script(
        self,
        package: str,
        target_version: str,
        use_local: bool = False,
    ) -> str:
        """Build script for fresh install via install.sh.

        Args:
            package: Package to install (cnspec or mql).
            target_version: Expected version after install.
            use_local: If True, use /work/install.sh (mounted from local repo).
                       If False, download from install.mondoo.com.
        """
        if use_local:
            install_cmd = f"bash /work/install.sh -p {package}"
            install_msg = f"Installing {package} via local install.sh..."
        else:
            install_cmd = f"curl -sSL https://install.mondoo.com/sh/{package} | bash -x -"
            install_msg = f"Installing {package} via install.mondoo.com..."

        verify = self._verify_version(package, target_version)
        # If installing cnspec, also verify cnquery symlink
        if package == "cnspec":
            verify += self._verify_version("cnquery", target_version)

        return textwrap.dedent(f"""\
            set -e

            # ---- setup ----
            {self.pkg_mgr.install_curl_script()}

            # ---- install {package} via install.sh ----
            echo ""
            echo "{install_msg}"
            {install_cmd}

            {verify}
        """)

    def build_install_sh_upgrade_script(
        self,
        base_version: str,
        target_version: str,
        stable_url: str,
        use_local: bool = False,
    ) -> str:
        """Build script for install.sh upgrade test.

        Installs cnquery from releases.mondoo.com (since install.mondoo.com now
        redirects cnquery to mql), then upgrades to mql via install.sh.

        Args:
            use_local: If True, use /work/install.sh (mounted from local repo).
                       If False, download from install.mondoo.com.
        """
        base_product = _mql_product(base_version)

        if use_local:
            install_cmd = "bash /work/install.sh -p mql"
            install_msg = "Upgrading to mql via local install.sh..."
        else:
            install_cmd = "curl -sSL https://install.mondoo.com/sh/mql | bash -"
            install_msg = "Upgrading to mql via install.mondoo.com..."

        return textwrap.dedent(f"""\
            set -e

            # ---- setup ----
            {self.pkg_mgr.install_curl_script()}

            {self._install_base_version_script(base_version, stable_url)}

            # ---- upgrade to mql via install.sh ----
            echo ""
            echo "{install_msg}"
            {install_cmd}

            {self._verify_version("mql", target_version)}

            # ---- verify {base_product} was removed ----
            echo ""
            echo "=== Verifying {base_product} was removed ==="
            {self.pkg_mgr.check_package_removed_script(base_product)}
        """)

    def build_aur_upgrade_script(self, target_version: str) -> str:
        """Build script for Arch Linux AUR upgrade test (cnquery -> mql)."""
        return textwrap.dedent(f"""\
            set -e

            # ---- setup ----
            {self.pkg_mgr.install_curl_script()}

            # ---- install cnquery from AUR ----
            echo "Installing cnquery from AUR..."
            {self.pkg_mgr.install_from_aur_script("cnquery")}

            # ---- upgrade: remove cnquery, install mql ----
            echo ""
            echo "Upgrading: removing cnquery, installing mql..."
            pacman -R --noconfirm cnquery cnquery-debug
            {self.pkg_mgr.install_from_aur_script("mql")}

            # ---- verify mql version ----
            {self._verify_version("mql", target_version)}

            # ---- verify cnquery package is gone ----
            echo ""
            echo "=== Verifying cnquery package is removed ==="
            {self.pkg_mgr.check_package_removed_script("cnquery")}
        """)

    def build_aur_mql_install_script(self, target_version: str) -> str:
        """Build script to install mql from AUR via makepkg."""
        return textwrap.dedent(f"""\
            set -e

            # ---- setup ----
            {self.pkg_mgr.install_curl_script()}

            # ---- install mql from AUR ----
            echo "Installing mql from AUR..."
            {self.pkg_mgr.install_from_aur_script("mql")}

            # ---- verify mql version ----
            {self._verify_version("mql", target_version)}
        """)

    def build_aur_cnspec_yay_script(self, target_version: str) -> str:
        """Build script to install cnspec from AUR via yay (also installs mql as dependency)."""
        return textwrap.dedent(f"""\
            set -e

            # ---- setup ----
            {self.pkg_mgr.install_curl_script()}
            pacman -S --noconfirm go

            # ---- install yay from AUR ----
            echo "Installing yay from AUR..."
            cd /tmp
            su test -c "git clone https://aur.archlinux.org/yay && cd yay && makepkg"
            cd yay && pacman -U --noconfirm yay-*.zst

            # ---- install cnspec via yay (pulls mql as dependency) ----
            echo ""
            echo "Installing cnspec via yay..."
            su test -c "yay -S --noconfirm cnspec"

            # ---- verify versions ----
            {self._verify_version("cnspec", target_version)}
            {self._verify_version("mql", target_version)}
        """)

    def build_self_upgrade_script(self, from_version: str, target_version: str) -> str:
        """Build script for self-upgrade test."""
        mondoo_yml = self._mondoo_config()

        return textwrap.dedent(f"""\
            set -e

            # ---- ensure curl is available ----
            {self.pkg_mgr.install_curl_script()}

            # ---- install mql {from_version} ----
            {self._download_tarball("mql", from_version, "/usr/local/bin")}

            # ---- install cnspec {from_version} ----
            {self._download_tarball("cnspec", from_version, "/usr/local/bin")}

            # ---- seed mondoo config ----
            mkdir -p ~/.config/mondoo
            cat > ~/.config/mondoo/mondoo.yml << 'MONDOOEOF'
            {mondoo_yml}MONDOOEOF

            # ---- trigger self-upgrade and verify version in output ----
            echo ""
            echo "=== mql run local -c mondoo.version (triggers self-upgrade) ==="
            MQL_RUN_OUT=$(mql run local -c 'mondoo.version' 2>&1) || true
            echo "$MQL_RUN_OUT"
            if echo "$MQL_RUN_OUT" | grep -qF '{target_version}'; then
                echo "PASS: mql self-upgraded to {target_version}"
            else
                echo "FAIL: mql output does not contain {target_version}"
                exit 1
            fi

            echo ""
            echo "=== cnspec run local -c mondoo.version (triggers self-upgrade) ==="
            CNSPEC_RUN_OUT=$(cnspec run local -c 'mondoo.version' 2>&1) || true
            echo "$CNSPEC_RUN_OUT"
            if echo "$CNSPEC_RUN_OUT" | grep -qF '{target_version}'; then
                echo "PASS: cnspec self-upgraded to {target_version}"
            else
                echo "FAIL: cnspec output does not contain {target_version}"
                exit 1
            fi
        """)
