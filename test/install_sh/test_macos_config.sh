#!/bin/sh
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Test that a macOS install keeps a single Mondoo config: service installs use
# the system config only, user installs the user config (mondoohq/installer#749).

# Globals and stub functions below are consumed by the eval'd install.sh functions.
# shellcheck disable=SC2034,SC2317

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SH="${SCRIPT_DIR}/../../install.sh"

PASS=0
FAIL=0
TESTS=0

assert_equals() {
  TESTS=$((TESTS + 1))
  _label="$1"; _got="$2"; _want="$3"
  if [ "$_got" = "$_want" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL: %s\n  expected: %s\n  got: %s\n' "$_label" "$_want" "$_got" >&2
  fi
}

# install.sh runs on source, so the functions under test are extracted instead.
extract_fn() {
  _snippet="$(sed -n "/^$1()/,/^}\$/p" "$INSTALL_SH")"
  if [ -z "$_snippet" ] || [ "$(printf '%s\n' "$_snippet" | tail -1)" != "}" ]; then
    printf 'ERROR: could not extract %s() from %s\n' "$1" "$INSTALL_SH" >&2
    return 1
  fi
  printf '%s\n' "$_snippet"
}

TOKEN_FN="$(extract_fn configure_macos_token)"
MIGRATE_FN="$(extract_fn migrate_macos_config)"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# login_config runs configure_macos_token with a stubbed login and prints the
# config file it would have written, plus '+user' if a user config exists.
login_config() {
  (
    MONDOO_SERVICE="$1"
    HOME="$WORK_DIR/home"
    MONDOO_MACOS_CONFIG="$WORK_DIR/system/mondoo.yml"
    rm -rf "${WORK_DIR:?}/home" "${WORK_DIR:?}/system"
    purple_bold() { :; }
    sudo_cmd() { "$@"; }
    run_login_cmd() { : > "$1/mondoo.yml"; echo "$1/mondoo.yml"; }
    eval "$TOKEN_FN"
    configure_macos_token
    [ -f "$HOME/.config/mondoo/mondoo.yml" ] && printf '+user\n'
    exit 0
  )
}

# migrate runs migrate_macos_config over the given user/system config contents
# ('-' means the file is absent) and prints the resulting state.
migrate() {
  (
    HOME="$WORK_DIR/home"
    MONDOO_MACOS_CONFIG="$WORK_DIR/system/mondoo.yml"
    _user_config="$HOME/.config/mondoo/mondoo.yml"
    rm -rf "${WORK_DIR:?}/home" "${WORK_DIR:?}/system"
    mkdir -p "$HOME/.config/mondoo" "$WORK_DIR/system"
    [ "$1" = '-' ] || echo "$1" > "$_user_config"
    [ "$2" = '-' ] || echo "$2" > "$MONDOO_MACOS_CONFIG"
    purple_bold() { :; }
    red() { :; }
    sudo_cmd() { "$@"; }
    eval "$MIGRATE_FN"
    migrate_macos_config
    printf 'user=%s system=%s\n' \
      "$(cat "$_user_config" 2>/dev/null || echo -)" \
      "$(cat "$MONDOO_MACOS_CONFIG" 2>/dev/null || echo -)"
  )
}

printf '==> Testing macOS config handling\n\n'

assert_equals "service install logs in to the system config" \
  "$(login_config enable)" "$WORK_DIR/system/mondoo.yml"
assert_equals "user install logs in to the user config" \
  "$(login_config '')" "$WORK_DIR/home/.config/mondoo/mondoo.yml
+user"

assert_equals "a user config is moved to the system config" \
  "$(migrate creds -)" "user=- system=creds"
assert_equals "a duplicate user config is removed" \
  "$(migrate creds creds)" "user=- system=creds"
# Two different registrations: dropping either one could remove valid
# credentials, so both are kept and the user is warned instead.
assert_equals "a diverged user config is kept" \
  "$(migrate other creds)" "user=other system=creds"
assert_equals "no user config is a no-op" \
  "$(migrate - creds)" "user=- system=creds"

printf '\n==> Results: %d/%d passed' "$PASS" "$TESTS"
if [ "$FAIL" -gt 0 ]; then
  printf ', %d FAILED\n' "$FAIL"
  exit 1
else
  printf '\n'
fi
