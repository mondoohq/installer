#!/bin/sh
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# The macOS service (-s enable) is a LaunchDaemon: launchd runs it as root,
# at boot. On a pkg install it runs /Library/Mondoo/bin/cnspec, which only
# root can change. A Homebrew prefix is owned by the logged-in user, so a
# service pointed at Homebrew's cnspec would let anything running as that
# user swap the binary and get root on the next start. The service is
# therefore refused on Homebrew installs, before anything is installed.
#
# This runs install.sh's real configure_macos_installer() with brew and
# pkgutil stubbed.

# Globals and stub functions below are consumed by the eval'd install.sh functions.
# shellcheck disable=SC2034,SC2317

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SH="${SCRIPT_DIR}/../../install.sh"

PASS=0
FAIL=0
TESTS=0

assert_contains() {
  TESTS=$((TESTS + 1))
  case "$2" in
    *"$3"*) PASS=$((PASS + 1)) ;;
    *)
      FAIL=$((FAIL + 1))
      printf 'FAIL: %s\n  expected to contain: %s\n  got: %s\n' "$1" "$3" "$2" >&2
      ;;
  esac
}

assert_not_contains() {
  TESTS=$((TESTS + 1))
  case "$2" in
    *"$3"*)
      FAIL=$((FAIL + 1))
      printf 'FAIL: %s\n  expected NOT to contain: %s\n  got: %s\n' "$1" "$3" "$2" >&2
      ;;
    *) PASS=$((PASS + 1)) ;;
  esac
}

# A directory with an executable `brew`, so the auto-detection's
# `[ -x "$(command -v brew)" ]` sees Homebrew without it being installed.
FAKE_BREW_DIR="$(mktemp -d)"
printf '#!/bin/sh\nexit 0\n' > "${FAKE_BREW_DIR}/brew"
chmod +x "${FAKE_BREW_DIR}/brew"
trap 'rm -rf "$FAKE_BREW_DIR"' EXIT

# pick_installer <requested installer> <service> <brew present> <pkg receipt>
# runs configure_macos_installer and prints the installer it settled on, every
# message it printed, and FAIL_CALLED if it stopped the install.
pick_installer() {
  (
    set +e
    MONDOO_INSTALLER="$1"
    MONDOO_SERVICE="$2"
    MONDOO_PRODUCT_NAME="cnspec"
    MONDOO_PKG_NAME="mondoo"
    if [ "$3" = true ]; then
      PATH="${FAKE_BREW_DIR}:/usr/bin:/bin"
    else
      PATH="/usr/bin:/bin"
    fi
    _receipt="$4"
    pkgutil() { [ "$_receipt" = true ]; }
    red() { printf 'MSG %s\n' "$1"; }
    purple() { printf 'MSG %s\n' "$1"; }
    purple_bold() { printf 'MSG %s\n' "$1"; }
    fail() { echo FAIL_CALLED; exit 1; }
    eval "$(sed -n '/^configure_macos_installer()/,/^}$/p' "$INSTALL_SH")"
    configure_macos_installer
    echo "INSTALLER=${MONDOO_INSTALLER}"
  ) 2>&1 || true
}

printf '\n==> -s enable on a Homebrew install is refused\n\n'

# Homebrew picked automatically: brew present, no pkg receipt
result=$(pick_installer "" enable true false)
assert_contains "auto-detected brew with the service stops the install" "$result" "FAIL_CALLED"
assert_not_contains "and never settles on an installer" "$result" "INSTALLER="
assert_contains "the refusal names the service" "$result" "-s enable"
assert_contains "the refusal points at the pkg" "$result" "-i pkg"

printf '\n==> Everything else is unchanged\n\n'

result=$(pick_installer "" "" true false)
assert_not_contains "brew without the service installs" "$result" "FAIL_CALLED"
assert_contains "brew without the service stays brew" "$result" "INSTALLER=brew"

# brew present, but the pkg is already installed: the pkg wins, and its
# root-owned layout supports the service.
result=$(pick_installer "" enable true true)
assert_not_contains "service on an existing pkg install is allowed" "$result" "FAIL_CALLED"
assert_contains "an existing pkg install stays pkg" "$result" "INSTALLER=pkg"

result=$(pick_installer "" enable false false)
assert_not_contains "service without brew is allowed" "$result" "FAIL_CALLED"
assert_contains "no brew means pkg" "$result" "INSTALLER=pkg"

result=$(pick_installer pkg enable true false)
assert_not_contains "-i pkg with the service is allowed" "$result" "FAIL_CALLED"
assert_contains "-i pkg stays pkg" "$result" "INSTALLER=pkg"

printf '\n==> Results: %d/%d passed' "$PASS" "$TESTS"
if [ "$FAIL" -gt 0 ]; then
  printf ', %d FAILED\n' "$FAIL"
  exit 1
else
  printf '\n'
fi
