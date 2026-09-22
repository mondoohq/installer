#!/bin/sh
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# MONDOO_INSTALLER names the platform's install method and is never empty once
# an OS is supported. It is read back in user-facing text --
#
#   ! The preview channel is not available via ${MONDOO_INSTALLER}.
#
# -- so an empty value is a sentence with a hole in it, which is what an Arch
# box with no AUR helper used to print. "Can this machine actually run it" is a
# separate question, answered inside mondoo_install, which names what is
# missing.
#
# This is the invariant that replaced the `[ -z "$MONDOO_INSTALLER" ]` check.

# Globals and stub functions below are consumed by the eval'd install.sh functions.
# shellcheck disable=SC2034,SC2317

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SH="${SCRIPT_DIR}/../../install.sh"

PASS=0
FAIL_COUNT=0
TESTS=0

ok() { TESTS=$((TESTS + 1)); PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
bad() {
  TESTS=$((TESTS + 1)); FAIL_COUNT=$((FAIL_COUNT + 1))
  printf 'FAIL: %s\n  %s\n' "$1" "$2" >&2
}

extract_fn() {
  _snippet="$(sed -n "/^$1()/,/^}\$/p" "$INSTALL_SH")"
  if [ -z "$_snippet" ] || [ "$(printf '%s\n' "$_snippet" | tail -1)" != "}" ]; then
    printf 'ERROR: could not extract %s() from %s\n' "$1" "$INSTALL_SH" >&2
    return 1
  fi
  printf '%s\n' "$_snippet"
}

red() { :; }
purple_bold() { :; }
fail() { return 0; }
MONDOO_PKG_NAME="mondoo"
MONDOO_PRODUCT_NAME="mondoo"

# Run a configurator with an empty PATH, so no package manager is found and
# every one takes the branch that used to blank the variable.
check_fn() {
  _fn="$1"; _want="${2:-}"
  eval "$(extract_fn "$_fn")"
  MONDOO_INSTALLER=""
  # Emptying PATH is the point: no yay, paru, apt, yum or zypper is findable,
  # so every configurator takes the branch that used to blank the variable.
  # Confined to a subshell so the rest of the suite keeps its PATH.
  # shellcheck disable=SC2123
  ( PATH=""; "$_fn" >/dev/null 2>&1; printf '%s' "${MONDOO_INSTALLER}" ) > /tmp/_in.$$ 2>/dev/null
  _got="$(cat /tmp/_in.$$)"; rm -f /tmp/_in.$$

  if [ -z "$_got" ]; then
    bad "$_fn leaves a name when its tool is missing" "MONDOO_INSTALLER is empty; it is printed in user-facing text"
  elif [ -z "$_want" ]; then
    ok "$_fn -> $_got, with no tool on PATH (no expected name pinned)"
  elif [ "$_got" != "$_want" ]; then
    bad "$_fn names its method" "expected '$_want', got '$_got'"
  else
    ok "$_fn -> $_got, with no tool on PATH"
  fi
}

# Discovered from install.sh, not listed here. A configurator added for a new
# platform is covered the day it is added; a list would cover it the day someone
# remembered this file, which is the same gap the runtime check guards against.
printf '\nMONDOO_INSTALLER is set even when the tool is absent\n'

FOUND=0
for _fn in $(grep -o '^configure_[a-z_]*_installer' "$INSTALL_SH" | sort -u); do
  FOUND=$((FOUND + 1))
  case "$_fn" in
    configure_archlinux_installer) check_fn "$_fn" aur ;;
    configure_rhel_installer)      check_fn "$_fn" yum ;;
    configure_debian_installer)    check_fn "$_fn" apt ;;
    configure_suse_installer)      check_fn "$_fn" zypper ;;
    # A configurator with no expected name yet still has to name something.
    *)                             check_fn "$_fn" ;;
  esac
done

if [ "$FOUND" -eq 0 ]; then
  bad "found the configurators" "no configure_*_installer matched in ${INSTALL_SH}"
else
  ok "discovered ${FOUND} configurators"
fi

# The sentinel is gone; nothing should reintroduce it.
printf '\nno empty assignment remains\n'
if grep -q 'MONDOO_INSTALLER=""' "$INSTALL_SH"; then
  bad "no MONDOO_INSTALLER=\"\" in install.sh" "$(grep -n 'MONDOO_INSTALLER=""' "$INSTALL_SH")"
else
  ok 'install.sh never blanks MONDOO_INSTALLER'
fi

printf '\n==> Results: %s/%s passed\n' "$PASS" "$TESTS"
[ "$FAIL_COUNT" -eq 0 ]
