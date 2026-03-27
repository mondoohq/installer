#!/bin/sh
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Test that install.sh flag parsing correctly maps to cnspec login parameters.
# This sources the relevant functions from install.sh and stubs out everything
# except the login command builder, then asserts the output.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SH="${SCRIPT_DIR}/../../install.sh"

PASS=0
FAIL=0
TESTS=0

assert_contains() {
  TESTS=$((TESTS + 1))
  _label="$1"; _haystack="$2"; _needle="$3"
  case "$_haystack" in
    *"$_needle"*) PASS=$((PASS + 1)) ;;
    *)
      FAIL=$((FAIL + 1))
      printf 'FAIL: %s\n  expected to contain: %s\n  got: %s\n' "$_label" "$_needle" "$_haystack" >&2
      ;;
  esac
}

assert_not_contains() {
  TESTS=$((TESTS + 1))
  _label="$1"; _haystack="$2"; _needle="$3"
  case "$_haystack" in
    *"$_needle"*)
      FAIL=$((FAIL + 1))
      printf 'FAIL: %s\n  expected NOT to contain: %s\n  got: %s\n' "$_label" "$_needle" "$_haystack" >&2
      ;;
    *) PASS=$((PASS + 1)) ;;
  esac
}

# capture_login_cmd runs install.sh's run_login_cmd in a subshell with stubbed
# dependencies, capturing the command that would be executed.
capture_login_cmd() {
  _updates_url="${1:-}"
  _providers_url="${2:-}"
  _api_proxy="${3:-}"
  _https_proxy_env="${4:-}"
  _annotation="${5:-}"
  _name="${6:-}"

  (
    # Stub sudo_cmd to just echo its arguments
    sudo_cmd() { echo "$@"; }

    # Set globals that run_login_cmd expects
    MONDOO_BINARY_PATH="cnspec"
    MONDOO_REGISTRATION_TOKEN="test-token"
    TIMER="60"
    SPLAY="60"
    UPDATES_URL="$_updates_url"
    PROVIDERS_URL="$_providers_url"
    API_PROXY="$_api_proxy"
    ANNOTATION="$_annotation"
    NAME="$_name"

    # Stub color functions
    lightblue_bold() { :; }
    purple_bold() { :; }

    # Override https_proxy if requested
    if [ -n "$_https_proxy_env" ]; then
      https_proxy="$_https_proxy_env"
      export https_proxy
    else
      unset https_proxy 2>/dev/null || true
      unset HTTPS_PROXY 2>/dev/null || true
    fi

    # Source just run_login_cmd from install.sh by extracting it
    # We can't source the whole file (it runs immediately), so we
    # redefine it here based on the actual function.
    eval "$(sed -n '/^run_login_cmd()/,/^}/p' "$INSTALL_SH")"

    # Replace the final "$@" execution with echo
    # Actually, sudo_cmd is stubbed to echo, so the output IS the command
    run_login_cmd /etc/opt/mondoo
  )
}

printf '==> Testing install.sh parameter passing\n\n'

# Test 1: -U flag passes --updates-url
result=$(capture_login_cmd "https://custom.example.com/updates/")
assert_contains "-U sets --updates-url" "$result" "--updates-url https://custom.example.com/updates/"

# Test 2: -p (deprecated) falls back to --updates-url
result=$(capture_login_cmd "" "https://old.example.com/providers/")
assert_contains "-p falls back to --updates-url" "$result" "--updates-url https://old.example.com/providers/"

# Test 3: -U takes priority over -p
result=$(capture_login_cmd "https://new/" "https://old/")
assert_contains "-U takes priority over -p" "$result" "--updates-url https://new/"
assert_not_contains "-U takes priority over -p (no old)" "$result" "--updates-url https://old/"

# Test 4: -x flag passes --api-proxy
result=$(capture_login_cmd "" "" "http://proxy:3128")
assert_contains "-x sets --api-proxy" "$result" "--api-proxy http://proxy:3128"

# Test 5: https_proxy env var auto-detects --api-proxy
result=$(capture_login_cmd "" "" "" "http://env-proxy:8080")
assert_contains "https_proxy env auto-detects --api-proxy" "$result" "--api-proxy http://env-proxy:8080"

# Test 6: -x takes priority over https_proxy env
result=$(capture_login_cmd "" "" "http://flag-proxy:3128" "http://env-proxy:8080")
assert_contains "-x takes priority over env" "$result" "--api-proxy http://flag-proxy:3128"
assert_not_contains "-x takes priority over env (no env)" "$result" "env-proxy"

# Test 7: no proxy flags or env means no --api-proxy
result=$(capture_login_cmd "" "" "" "")
assert_not_contains "no proxy = no --api-proxy" "$result" "--api-proxy"

# Test 8: no updates URL on standard install means no --updates-url
result=$(capture_login_cmd "" "" "" "")
assert_not_contains "standard install = no --updates-url" "$result" "--updates-url"

# Test 9: --annotation is passed
result=$(capture_login_cmd "" "" "" "" "foo=bar")
assert_contains "--annotation is passed" "$result" "--annotation foo=bar"

# Test 10: --name is passed
result=$(capture_login_cmd "" "" "" "" "" "my-host")
assert_contains "--name is passed" "$result" "--name my-host"

# Test 11: base login params are always present
result=$(capture_login_cmd)
assert_contains "has --token" "$result" "--token test-token"
assert_contains "has --config" "$result" "--config /etc/opt/mondoo/mondoo.yml"
assert_contains "has --timer" "$result" "--timer 60"
assert_contains "has --splay" "$result" "--splay 60"
assert_contains "has cnspec login" "$result" "cnspec login"

printf '\n==> Results: %d/%d passed' "$PASS" "$TESTS"
if [ "$FAIL" -gt 0 ]; then
  printf ', %d FAILED\n' "$FAIL"
  exit 1
else
  printf '\n'
fi
