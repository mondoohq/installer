#!/bin/sh
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Test that install.sh flag parsing correctly maps to cnspec login parameters,
# and that -x / https_proxy reach the rest of the install (the script's own
# downloads, and package managers run through sudo). This sources the relevant
# functions from install.sh and stubs out everything else, then asserts the
# output.

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
    # shellcheck disable=SC2034 # these are consumed by the eval'd run_login_cmd
    MONDOO_BINARY_PATH="cnspec"
    # shellcheck disable=SC2034
    MONDOO_REGISTRATION_TOKEN="test-token"
    # shellcheck disable=SC2034
    TIMER="60"
    # shellcheck disable=SC2034
    SPLAY="60"
    # shellcheck disable=SC2034
    UPDATES_URL="$_updates_url"
    # shellcheck disable=SC2034
    PROVIDERS_URL="$_providers_url"
    # shellcheck disable=SC2034
    API_PROXY="$_api_proxy"
    # shellcheck disable=SC2034
    ANNOTATION="$_annotation"
    # shellcheck disable=SC2034
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

# capture_proxy_env resolves the proxy the way install.sh does right after flag
# parsing and prints what the rest of the script (and any child process) sees.
capture_proxy_env() {
  _api_proxy="${1:-}"
  _https_proxy_env="${2:-}"

  (
    API_PROXY="$_api_proxy"
    if [ -n "$_https_proxy_env" ]; then
      https_proxy="$_https_proxy_env"
      export https_proxy
    else
      unset https_proxy 2>/dev/null || true
      unset HTTPS_PROXY 2>/dev/null || true
    fi

    eval "$(sed -n '/^apply_proxy_env()/,/^}/p' "$INSTALL_SH")"
    apply_proxy_env

    # A child shell only sees exported variables, which is what curl/apt get.
    printf 'API_PROXY=%s https_proxy=%s HTTPS_PROXY=%s child=%s' \
      "$API_PROXY" "${https_proxy:-}" "${HTTPS_PROXY:-}" "$(sh -c 'printf %s "${https_proxy:-}"')"
  )
}

# capture_sudo_cmd runs install.sh's sudo_cmd as a non-root user with a fake
# sudo on PATH that prints its argv, so the exact privileged command is asserted.
capture_sudo_cmd() {
  _https_proxy_env="${1:-}"
  shift

  (
    _fake_bin="$(mktemp -d)"
    printf '#!/bin/sh\necho "sudo $*"\n' > "$_fake_bin/sudo"
    chmod +x "$_fake_bin/sudo"
    PATH="$_fake_bin:$PATH"

    # Pretend to be an unprivileged user; stub the helpers sudo_cmd may call.
    id() { echo 1000; }
    red() { :; }
    fail() { exit 1; }

    if [ -n "$_https_proxy_env" ]; then
      https_proxy="$_https_proxy_env"
      export https_proxy
    else
      unset https_proxy 2>/dev/null || true
      unset HTTPS_PROXY 2>/dev/null || true
    fi

    eval "$(sed -n '/^sudo_cmd()/,/^}/p' "$INSTALL_SH")"
    sudo_cmd "$@"
    rm -rf "$_fake_bin"
  )
}

printf '\n==> Testing install.sh proxy handling\n\n'

# Test 12: -x exports https_proxy for curl and the package managers
result=$(capture_proxy_env "http://proxy:3128")
assert_contains "-x sets https_proxy" "$result" "https_proxy=http://proxy:3128"
assert_contains "-x sets HTTPS_PROXY" "$result" "HTTPS_PROXY=http://proxy:3128"
assert_contains "-x is exported to child processes" "$result" "child=http://proxy:3128"

# Test 13: -x overrides an inherited https_proxy
result=$(capture_proxy_env "http://flag-proxy:3128" "http://env-proxy:8080")
assert_contains "-x overrides inherited https_proxy" "$result" "https_proxy=http://flag-proxy:3128"
assert_not_contains "-x overrides inherited https_proxy (no env)" "$result" "env-proxy"

# Test 14: an inherited https_proxy becomes the API proxy for later steps
result=$(capture_proxy_env "" "http://env-proxy:8080")
assert_contains "inherited https_proxy becomes API_PROXY" "$result" "API_PROXY=http://env-proxy:8080"

# Test 15: no proxy leaves the environment untouched
result=$(capture_proxy_env)
assert_contains "no proxy = nothing exported" "$result" "API_PROXY= https_proxy= HTTPS_PROXY= child="

# Test 16: sudo_cmd carries the proxy across sudo's env_reset
result=$(capture_sudo_cmd "http://proxy:3128" apt update)
assert_contains "sudo_cmd passes the proxy through sudo" "$result" "sudo env https_proxy=http://proxy:3128 HTTPS_PROXY=http://proxy:3128 apt update"

# Test 17: sudo_cmd without a proxy is plain sudo
result=$(capture_sudo_cmd "" apt update)
assert_contains "sudo_cmd without proxy is plain sudo" "$result" "sudo apt update"
assert_not_contains "sudo_cmd without proxy does not use env" "$result" "env"

printf '\n==> Results: %d/%d passed' "$PASS" "$TESTS"
if [ "$FAIL" -gt 0 ]; then
  printf ', %d FAILED\n' "$FAIL"
  exit 1
else
  printf '\n'
fi
