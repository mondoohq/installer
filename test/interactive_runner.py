#!/usr/bin/env python3
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

"""Interactive test runner with curses-based TUI for selecting tests."""

from __future__ import annotations

import curses
import json
import os
import subprocess
import sys
import urllib.request

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------

TEST_TYPES = [
    {
        "name": "Fresh Install (install.sh)",
        "test": "test/auto_update/test_install_sh.py::test_install_sh_fresh_install",
        "needs_distro": True,
        "needs_package": True,
        "needs_version": True,
        "supports_local_install_sh": True,
        "excluded_pkg_mgrs": {"pacman"},
    },
    {
        "name": "Upgrade via install.sh",
        "test": "test/auto_update/test_install_sh.py::test_install_sh_upgrade",
        "needs_distro": True,
        "needs_package": False,
        "needs_version": True,
        "needs_upgrade_from": True,
        "supports_local_install_sh": True,
        "excluded_pkg_mgrs": {"pacman"},
    },
    {
        "name": "Mondoo Metapackage",
        "test": "test/auto_update/test_mondoo_pkg.py::test_mondoo_pkg",
        "needs_distro": True,
        "needs_package": False,
        "needs_version": True,
        "excluded_pkg_mgrs": {"pacman"},
    },
    {
        "name": "Package Upgrade (cnquery -> mql)",
        "test": "test/auto_update/test_upgrade.py::test_upgrade",
        "needs_distro": True,
        "needs_package": False,
        "needs_version": True,
        "excluded_pkg_mgrs": {"pacman"},
    },
    {
        "name": "Auto-Update",
        "test": "test/auto_update/test_auto_update.py::test_auto_update",
        "needs_distro": True,
        "needs_package": False,
        "needs_version": True,
        "excluded_pkg_mgrs": {"pacman"},
    },
    {
        "name": "Self-Upgrade",
        "test": "test/auto_update/test_upgrade.py::test_self_upgrade",
        "needs_distro": True,
        "needs_package": False,
        "needs_version": True,
        "needs_self_upgrade_from": True,
        "excluded_pkg_mgrs": {"pacman"},
    },
    {
        "name": "AUR: mql via makepkg",
        "test": "test/auto_update/test_aur.py::test_aur_mql_makepkg",
        "needs_distro": False,
        "needs_package": False,
        "needs_version": True,
        "fixed_distro": "arch",
    },
    {
        "name": "AUR: cnspec via yay",
        "test": "test/auto_update/test_aur.py::test_aur_cnspec_yay",
        "needs_distro": False,
        "needs_package": False,
        "needs_version": True,
        "fixed_distro": "arch",
    },
    {
        "name": "AUR: upgrade cnquery -> mql",
        "test": "test/auto_update/test_upgrade.py::test_aur_upgrade",
        "needs_distro": False,
        "needs_package": False,
        "needs_version": True,
        "fixed_distro": "arch",
    },
]

DISTROS = [
    ("Debian 11", "debian:11", "apt"),
    ("Debian 12", "debian:12", "apt"),
    ("Debian 13", "debian:13", "apt"),
    ("Ubuntu 18.04", "ubuntu:18.04", "apt"),
    ("Ubuntu 20.04", "ubuntu:20.04", "apt"),
    ("Ubuntu 22.04", "ubuntu:22.04", "apt"),
    ("Ubuntu 24.04", "ubuntu:24.04", "apt"),
    ("AlmaLinux 9", "almalinux:9", "dnf"),
    ("Rocky Linux 8", "rockylinux:8", "dnf"),
    ("Rocky Linux 9", "rockylinux:9", "dnf"),
    ("CentOS Stream 9", "quay.io/centos/centos:stream9", "dnf"),
    ("Fedora 40", "fedora:40", "dnf"),
    ("Fedora 41", "fedora:41", "dnf"),
    ("Red Hat UBI 8", "redhat/ubi8", "dnf"),
    ("Red Hat UBI 9", "redhat/ubi9", "dnf"),
    ("Red Hat UBI 10", "redhat/ubi10", "dnf"),
    ("Oracle Linux 8", "oraclelinux:8", "dnf"),
    ("Oracle Linux 9", "oraclelinux:9", "dnf"),
    ("SUSE SLE 15.6", "registry.suse.com/suse/sle15:15.6", "zypper"),
    ("Arch Linux", "archlinux:latest", "pacman"),
]

PACKAGES = ["cnspec", "mql"]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def fetch_latest_version() -> str:
    """Fetch the latest mql version from releases.mondoo.com."""
    try:
        url = "https://releases.mondoo.com/mql/latest.json"
        with urllib.request.urlopen(url, timeout=5) as resp:
            data = json.loads(resp.read().decode())
            return data.get("version", "")
    except Exception:
        return ""


# ---------------------------------------------------------------------------
# Curses UI components
# ---------------------------------------------------------------------------

def draw_header(stdscr: curses.window, title: str) -> int:
    """Draw a title header, return the next y position."""
    stdscr.clear()
    h, w = stdscr.getmaxyx()
    stdscr.attron(curses.A_BOLD)
    stdscr.addnstr(0, 0, title, w - 1)
    stdscr.attroff(curses.A_BOLD)
    stdscr.addnstr(1, 0, "-" * min(len(title), w - 1), w - 1)
    return 3


def single_select(stdscr: curses.window, title: str, items: list[str]) -> int | None:
    """Single-select menu. Returns index or None on quit."""
    cursor = 0
    while True:
        y = draw_header(stdscr, title)
        h, w = stdscr.getmaxyx()
        hint = "Arrow keys: navigate | Enter: select | q: quit"
        stdscr.addnstr(y - 1, 0, hint, w - 1, curses.A_DIM)
        for i, item in enumerate(items):
            if y + i >= h - 1:
                break
            prefix = "> " if i == cursor else "  "
            attr = curses.A_REVERSE if i == cursor else 0
            stdscr.addnstr(y + i, 0, f"{prefix}{item}", w - 1, attr)
        stdscr.refresh()
        key = stdscr.getch()
        if key == curses.KEY_UP and cursor > 0:
            cursor -= 1
        elif key == curses.KEY_DOWN and cursor < len(items) - 1:
            cursor += 1
        elif key in (curses.KEY_ENTER, 10, 13):
            return cursor
        elif key in (ord("q"), ord("Q"), 27):
            return None


def multi_select(
    stdscr: curses.window,
    title: str,
    items: list[str],
    preselected: set[int] | None = None,
) -> list[int] | None:
    """Multi-select checklist. Returns list of selected indices or None on quit."""
    cursor = 0
    selected = set(preselected) if preselected else set()
    while True:
        y = draw_header(stdscr, title)
        h, w = stdscr.getmaxyx()
        hint = "Arrow keys: navigate | Space: toggle | a: all | n: none | Enter: confirm | q: quit"
        stdscr.addnstr(y - 1, 0, hint, w - 1, curses.A_DIM)
        for i, item in enumerate(items):
            if y + i >= h - 1:
                break
            check = "[x]" if i in selected else "[ ]"
            prefix = "> " if i == cursor else "  "
            attr = curses.A_REVERSE if i == cursor else 0
            stdscr.addnstr(y + i, 0, f"{prefix}{check} {item}", w - 1, attr)
        stdscr.refresh()
        key = stdscr.getch()
        if key == curses.KEY_UP and cursor > 0:
            cursor -= 1
        elif key == curses.KEY_DOWN and cursor < len(items) - 1:
            cursor += 1
        elif key == ord(" "):
            selected ^= {cursor}
        elif key in (ord("a"), ord("A")):
            selected = set(range(len(items)))
        elif key in (ord("n"), ord("N")):
            selected.clear()
        elif key in (curses.KEY_ENTER, 10, 13):
            return sorted(selected) if selected else None
        elif key in (ord("q"), ord("Q"), 27):
            return None


def text_input(stdscr: curses.window, title: str, prompt: str, default: str = "") -> str | None:
    """Simple text input. Returns string or None on quit."""
    value = default
    while True:
        y = draw_header(stdscr, title)
        h, w = stdscr.getmaxyx()
        hint = "Type to edit | Enter: confirm | Esc: quit"
        stdscr.addnstr(y - 1, 0, hint, w - 1, curses.A_DIM)
        stdscr.addnstr(y, 0, f"{prompt}: {value}", w - 1)
        stdscr.addnstr(y + 1, 0, " " * (w - 1), w - 1)
        # Place cursor
        cursor_x = min(len(prompt) + 2 + len(value), w - 2)
        stdscr.move(y, cursor_x)
        stdscr.refresh()
        key = stdscr.getch()
        if key in (curses.KEY_ENTER, 10, 13):
            return value
        elif key == 27:
            return None
        elif key in (curses.KEY_BACKSPACE, 127, 8):
            value = value[:-1]
        elif 32 <= key <= 126:
            value += chr(key)


def yes_no(stdscr: curses.window, title: str, prompt: str, default: bool = False) -> bool | None:
    """Yes/No prompt. Returns bool or None on quit."""
    cursor = 0 if default else 1
    options = ["Yes", "No"]
    while True:
        y = draw_header(stdscr, title)
        h, w = stdscr.getmaxyx()
        stdscr.addnstr(y, 0, prompt, w - 1)
        for i, opt in enumerate(options):
            prefix = "> " if i == cursor else "  "
            attr = curses.A_REVERSE if i == cursor else 0
            stdscr.addnstr(y + 2 + i, 0, f"{prefix}{opt}", w - 1, attr)
        stdscr.refresh()
        key = stdscr.getch()
        if key == curses.KEY_UP and cursor > 0:
            cursor -= 1
        elif key == curses.KEY_DOWN and cursor < 1:
            cursor += 1
        elif key in (curses.KEY_ENTER, 10, 13):
            return cursor == 0
        elif key in (ord("q"), ord("Q"), 27):
            return None


def confirm_and_run(stdscr: curses.window, cmd_parts: list[str]) -> bool:
    """Show command and ask for confirmation. Returns True to run."""
    cmd_str = " \\\n    ".join(cmd_parts)
    y = draw_header(stdscr, "Confirm")
    h, w = stdscr.getmaxyx()
    stdscr.addnstr(y, 0, "Command to run:", w - 1, curses.A_BOLD)
    for i, line in enumerate(cmd_str.split("\n")):
        if y + 2 + i >= h - 3:
            break
        stdscr.addnstr(y + 2 + i, 0, line, w - 1)
    bottom = min(y + 2 + len(cmd_str.split("\n")) + 1, h - 2)
    stdscr.addnstr(bottom, 0, "Press Enter to run, q to cancel", w - 1, curses.A_DIM)
    stdscr.refresh()
    while True:
        key = stdscr.getch()
        if key in (curses.KEY_ENTER, 10, 13):
            return True
        if key in (ord("q"), ord("Q"), 27):
            return False


# ---------------------------------------------------------------------------
# Main interactive flow
# ---------------------------------------------------------------------------

def interactive_main(stdscr: curses.window) -> list[str] | None:
    """Run the interactive selector and return the pytest command parts, or None."""
    curses.curs_set(0)

    # Step 1: Select test type
    test_names = [t["name"] for t in TEST_TYPES]
    idx = single_select(stdscr, "Select Test Type", test_names)
    if idx is None:
        return None
    test_type = TEST_TYPES[idx]

    cmd = ["pytest", test_type["test"], "-v"]

    # Step 2: Select distro(s)
    if test_type.get("needs_distro"):
        excluded = test_type.get("excluded_pkg_mgrs", set())
        filtered = [(name, image, pm) for name, image, pm in DISTROS if pm not in excluded]
        distro_names = [f"{name} ({image})" for name, image, _ in filtered]
        selected = multi_select(stdscr, "Select Distro(s)", distro_names)
        if selected is None:
            return None
        for i in selected:
            cmd.extend(["--distro", filtered[i][1]])
    elif test_type.get("fixed_distro"):
        cmd.extend(["--distro", test_type["fixed_distro"]])

    # Step 3: Select package(s)
    if test_type.get("needs_package"):
        pkg_selected = multi_select(
            stdscr,
            "Select Package(s)",
            PACKAGES,
            preselected={0, 1},
        )
        if pkg_selected is None:
            return None
        for i in pkg_selected:
            cmd.extend(["--package", PACKAGES[i]])

    # Step 4: Enter version
    if test_type.get("needs_version"):
        default_ver = fetch_latest_version()
        version = text_input(stdscr, "Version", "Install version", default=default_ver)
        if version is None:
            return None
        cmd.extend(["--install-version", version])

    # Step 4b: Upgrade-from version (if needed)
    if test_type.get("needs_upgrade_from"):
        upgrade_from = text_input(stdscr, "Upgrade From", "Base version to upgrade from", default="12.0.0")
        if upgrade_from is None:
            return None
        cmd.extend(["--install-sh-upgrade-from", upgrade_from])

    if test_type.get("needs_self_upgrade_from"):
        su_from = text_input(stdscr, "Self-Upgrade From", "Version to install before self-upgrade", default="")
        if su_from is None:
            return None
        if su_from:
            cmd.extend(["--self-upgrade-from", su_from])

    # Step 5: Extra options
    if test_type.get("supports_local_install_sh"):
        use_local = yes_no(stdscr, "Options", "Use local install.sh?", default=False)
        if use_local is None:
            return None
        if use_local:
            cmd.append("--use-local-install-sh")

    shell_fail = yes_no(stdscr, "Options", "Shell on failure?", default=False)
    if shell_fail is None:
        return None
    if shell_fail:
        cmd.append("--shell-on-failure")

    # Step 6: Confirm
    if not confirm_and_run(stdscr, cmd):
        return None

    return cmd


def main() -> None:
    """Entry point."""
    cmd = curses.wrapper(interactive_main)
    if cmd is None:
        print("Cancelled.")
        sys.exit(1)

    # Replace leading "pytest" with the run_tests.sh wrapper
    test_dir = os.path.dirname(os.path.abspath(__file__))
    wrapper = os.path.join(test_dir, "run_tests.sh")
    cmd[0] = wrapper

    print(f"\nRunning: {' '.join(cmd)}\n")
    repo_root = os.path.join(test_dir, "..")
    result = subprocess.run(cmd, cwd=repo_root)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
