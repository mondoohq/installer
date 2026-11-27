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
  _api_endpoint="${7:-}"

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
    # shellcheck disable=SC2034
    API_ENDPOINT="$_api_endpoint"

    # Stub color functions
    lightblue_bold() { :; }
    purple_bold() { :; }

    # Override https_proxy if requested
    no_proxy="internal.example"
    export no_proxy
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

# Test 10b: -e passes --api-endpoint, and only when set
result=$(capture_login_cmd "" "" "" "" "" "" "https://api.internal.example.com")
assert_contains "-e sets --api-endpoint" "$result" "--api-endpoint https://api.internal.example.com"
result=$(capture_login_cmd)
assert_not_contains "no -e means no --api-endpoint" "$result" "--api-endpoint"

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
  _http_proxy_env="${3:-}"

  (
    API_PROXY="$_api_proxy"
    no_proxy="internal.example"
    export no_proxy
    if [ -n "$_https_proxy_env" ]; then
      https_proxy="$_https_proxy_env"
      export https_proxy
    else
      unset https_proxy 2>/dev/null || true
      unset HTTPS_PROXY 2>/dev/null || true
    fi
    if [ -n "$_http_proxy_env" ]; then
      http_proxy="$_http_proxy_env"
      export http_proxy
    else
      unset http_proxy 2>/dev/null || true
      unset HTTP_PROXY 2>/dev/null || true
    fi

    red() { printf '%s\n' "$1"; }
    fail() { exit 1; }
    eval "$(sed -n '/^apply_proxy_env()/,/^}/p' "$INSTALL_SH")"
    apply_proxy_env

    # A child shell only sees exported variables, which is what curl/apt get.
    printf 'API_PROXY=%s https_proxy=%s HTTPS_PROXY=%s http_proxy=%s child=%s' \
      "$API_PROXY" "${https_proxy:-}" "${HTTPS_PROXY:-}" "${http_proxy:-}" \
      "$(sh -c 'printf %s "${https_proxy:-}"')"
  ) 2>/dev/null || true
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
    # Narrow on purpose: a stub that answers everything would keep returning
    # 1000 if the real check ever became `id -ru`, and the test would pass
    # while covering nothing.
    id() { case "$1" in -u|-ru) echo 1000 ;; *) command id "$@" ;; esac; }
    red() { :; }
    fail() { exit 1; }

    no_proxy="internal.example"
    export no_proxy
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
assert_contains "no proxy = nothing exported" "$result" "API_PROXY= https_proxy= HTTPS_PROXY= http_proxy= child="

# Test 16: sudo_cmd carries the proxy across sudo's env_reset
result=$(capture_sudo_cmd "http://proxy:3128" apt update)
assert_contains "sudo_cmd passes the proxy through sudo" "$result" "sudo env https_proxy=http://proxy:3128 HTTPS_PROXY=http://proxy:3128 http_proxy=http://proxy:3128 HTTP_PROXY=http://proxy:3128"

# Test 17: sudo_cmd without a proxy is plain sudo
result=$(capture_sudo_cmd "" apt update)
assert_contains "sudo_cmd without proxy is plain sudo" "$result" "sudo apt update"
assert_not_contains "sudo_cmd without proxy does not use env" "$result" "env"

# capture_autoupdater runs install.sh's real autoupdater() with sudo_cmd
# passed through and `tee` capturing stdin, so the assertions below see the
# exact bytes that would land in the cron job or the launchd plist. The
# mkdir, launchctl and messages it runs are logged alongside; whatever tee
# would echo back to the terminal shows up as TEE_ECHO.
capture_autoupdater() {
  _os="$1"
  _proxy="$2"
  _installer="${3:-pkg}"
  (
    set +e
    _out="$(mktemp)"
    # shellcheck disable=SC2034 # consumed by the eval'd autoupdater
    OS="$_os"
    API_PROXY="$_proxy"
    # shellcheck disable=SC2034 # consumed by the eval'd autoupdater
    MONDOO_INSTALLER="$_installer"
    # shellcheck disable=SC2034 # consumed by the eval'd autoupdater
    MONDOO_PRODUCT_NAME="cnspec"
    # shellcheck disable=SC2034 # consumed by the eval'd autoupdater
    MONDOO_BREW_FORMULA="mondoohq/mondoo/cnspec"
    purple_bold() { :; }
    purple() { printf 'MSG %s\n' "$1" >> "$_out"; }
    red() { :; }
    fail() { exit 1; }
    sudo_cmd() { "$@"; }
    tee() { cat >> "$_out"; echo TEE_ECHO; }
    launchctl() { printf 'launchctl %s\n' "$*" >> "$_out"; }
    curl() { :; }
    cp() { :; }
    mkdir() { printf 'mkdir %s\n' "$*" >> "$_out"; }
    chmod() { printf 'chmod %s\n' "$*" >> "$_out"; }
    rm() { printf 'rm %s\n' "$*" >> "$_out"; }
    sleep() { :; }
    eval "$(sed -n '/^autoupdater()/,/^}$/p' "$INSTALL_SH")"
    autoupdater 2>/dev/null >> "$_out"
    cat "$_out"
    command rm -f "$_out"
  ) || true
}

# Test 18a: http_proxy alone is enough -- an https-only lookup would miss it.
result=$(capture_proxy_env "" "" "http://http-only:3128")
assert_contains "http_proxy alone becomes API_PROXY" "$result" "API_PROXY=http://http-only:3128"

# Test 18b: no_proxy survives sudo's env_reset, or a host the user excluded
# would start going through the proxy only under sudo.
result=$(capture_sudo_cmd "http://proxy:3128" apt update)
assert_contains "sudo_cmd carries no_proxy" "$result" "no_proxy=internal.example"

# Test 18c: a value that would need quoting to be safe in the files this script
# generates is refused outright.
result=$(capture_proxy_env "http://x';id>/tmp/pwn;'")
assert_contains "a proxy with a quote is rejected" "$result" "not allowed"
result=$(capture_proxy_env 'http://proxy:3128/?a=1&b=2')
assert_contains "a proxy with an XML metacharacter is rejected" "$result" "not allowed"

printf '\n==> Testing the generated auto updater job\n\n'

# Test 18: the Linux cron job exports the proxy rather than passing -x, so the
# value never appears in `ps` output for the scheduled run.
result=$(capture_autoupdater Debian "http://proxy:3128")
assert_contains "cron job exports https_proxy" "$result" "export https_proxy='http://proxy:3128'"
assert_contains "cron job exports http_proxy too" "$result" "http_proxy='http://proxy:3128'"
assert_not_contains "cron job does not pass -x" "$result" " -x "

# Test 19: and is not readable by anyone but root, since the proxy URL may
# carry credentials.
assert_contains "cron job is chmod 700" "$result" "chmod 700"
assert_not_contains "cron job is not world readable" "$result" "chmod a+x /etc/cron.weekly"

# Test 20: without a proxy the job is unchanged.
result=$(capture_autoupdater Debian "")
assert_not_contains "no proxy means no export" "$result" "https_proxy"
assert_contains "no proxy still writes the updater" "$result" "install.mondoo.com/sh"

# Test 21: on macOS the proxy goes into EnvironmentVariables, not
# ProgramArguments, so it stays out of `ps` and launchd's job listing.
result=$(capture_autoupdater macOS "http://proxy:3128")
assert_contains "plist sets https_proxy" "$result" "<key>https_proxy</key>"
assert_contains "plist sets http_proxy" "$result" "<key>http_proxy</key>"
assert_not_contains "plist does not pass -x" "$result" "<string>-x</string>"

# Test 22: the pkg install copies the updater into /Library/Mondoo/bin, so
# make sure the directory is there rather than trusting the package for it.
result=$(capture_autoupdater macOS "" pkg)
assert_contains "pkg updater creates its bin directory" "$result" "mkdir -p /Library/Mondoo/bin"
assert_contains "pkg updater still loads the job" "$result" "launchctl load /Library/LaunchDaemons/com.mondoo.autoupdater.plist"

# Test 23: writing the plist does not echo it back to the terminal.
assert_not_contains "launchd plist is not printed" "$result" "TEE_ECHO"
result=$(capture_autoupdater Debian "")
assert_not_contains "cron job is not printed" "$result" "TEE_ECHO"

# Test 24: a Homebrew install has no /Library/Mondoo/bin, and the launchd job
# runs as root with '-i pkg' -- brew refuses root, and pkg would put a second
# cnspec next to Homebrew's. Homebrew updates it, so no job is created.
result=$(capture_autoupdater macOS "" brew)
assert_not_contains "brew install writes no updater plist" "$result" "<plist"
assert_not_contains "brew install loads no updater job" "$result" "launchctl load"
assert_not_contains "brew install copies no updater script" "$result" "/Library/Mondoo/bin"
assert_contains "brew install points at brew upgrade" "$result" "brew upgrade mondoohq/mondoo/cnspec"

# capture_macos_service runs install.sh's real service() for macOS, logging
# the commands it runs, the messages it prints and the plist it writes.
capture_macos_service() {
  _installer="$1"
  (
    set +e
    _out="$(mktemp)"
    # shellcheck disable=SC2034 # consumed by the eval'd service
    OS="macOS"
    # shellcheck disable=SC2034 # consumed by the eval'd service
    MONDOO_INSTALLER="$_installer"
    # shellcheck disable=SC2034 # consumed by the eval'd service
    MONDOO_PRODUCT_NAME="cnspec"
    # shellcheck disable=SC2034 # consumed by the eval'd service
    MONDOO_PKG_NAME="cnspec"
    purple_bold() { :; }
    purple() { printf 'MSG %s\n' "$1" >> "$_out"; }
    sudo_cmd() { "$@"; }
    tee() { cat >> "$_out"; }
    launchctl() { printf 'launchctl %s\n' "$*" >> "$_out"; }
    rm() { :; }
    sleep() { :; }
    eval "$(sed -n '/^service()/,/^}$/p' "$INSTALL_SH")"
    service >/dev/null 2>&1
    cat "$_out"
    command rm -f "$_out"
  ) || true
}

# Test 25: the pkg service runs the pkg's binary.
result=$(capture_macos_service pkg)
assert_contains "pkg service runs /Library/Mondoo/bin/cnspec" "$result" "<string>/Library/Mondoo/bin/cnspec</string>"
assert_contains "pkg service is loaded" "$result" "launchctl bootstrap system"

# Test 26: the service is a root launchd job, and Homebrew's cnspec sits in a
# prefix the user owns. A root job running it would hand that user root, so a
# Homebrew install gets no service and is pointed at the pkg.
result=$(capture_macos_service brew)
assert_not_contains "brew install writes no service plist" "$result" "<plist"
assert_not_contains "brew install loads no service" "$result" "launchctl bootstrap"
assert_contains "brew install points at the pkg" "$result" "-i pkg -s enable"

# capture_macos_login runs install.sh's real configure_macos_token() and the
# helpers it calls, logging every command and whether it went through sudo.
capture_macos_login() {
  _service="$1"
  _installer="${2:-pkg}"
  (
    set +e
    _home="$(mktemp -d)"
    # shellcheck disable=SC2034 # consumed by the eval'd functions
    HOME="$_home"
    # shellcheck disable=SC2034 # consumed by the eval'd functions
    MONDOO_SERVICE="$_service"
    # shellcheck disable=SC2034 # consumed by the eval'd functions
    MONDOO_INSTALLER="$_installer"
    # shellcheck disable=SC2034 # consumed by the eval'd functions
    MONDOO_BINARY_PATH="cnspec"
    # shellcheck disable=SC2034 # consumed by the eval'd functions
    MONDOO_REGISTRATION_TOKEN="tok"
    # shellcheck disable=SC2034 # consumed by the eval'd functions
    TIMER=60 SPLAY=60 UPDATES_URL="https://example.invalid" API_PROXY="" API_ENDPOINT=""
    https_proxy="" HTTPS_PROXY=""
    purple_bold() { :; }
    lightblue_bold() { :; }
    sudo_cmd() { echo "SUDO $*"; }
    cnspec() { echo "USER cnspec $*"; }
    for _fn in run_login_cmd configure_macos_token install_macos_service_config; do
      eval "$(sed -n "/^${_fn}()/,/^}\$/p" "$INSTALL_SH")"
    done
    configure_macos_token
    command rm -rf "$_home"
  ) || true
}

# Test 27: the login writes a config in the user's home directory, so it runs
# as the user. Under sudo the file would be owned by root and the status check
# after it (run as the user) would report the registration as failed.
result=$(capture_macos_login disable)
assert_contains "macOS login runs as the user" "$result" "USER cnspec login --config"
assert_not_contains "macOS login does not use sudo" "$result" "SUDO cnspec login"

# Test 28: with the service enabled, the system config directory is created
# before the copy (a Homebrew install has no /Library/Mondoo).
result=$(capture_macos_login enable)
assert_contains "service config dir is created" "$result" "SUDO mkdir -p /Library/Mondoo/etc"
assert_contains "service config is copied" "$result" "/Library/Mondoo/etc/mondoo.yml"
assert_contains "service config is 0600" "$result" "SUDO chmod 0600 /Library/Mondoo/etc/mondoo.yml"

# Test 28b: Homebrew installs get no service, so the system config is not
# copied either.
result=$(capture_macos_login enable brew)
assert_contains "brew login still runs as the user" "$result" "USER cnspec login --config"
assert_not_contains "brew install copies no system config" "$result" "/Library/Mondoo/etc"

# capture_reclaim runs reclaim_macos_user_config() against a real file.
# _owner is what stat reports as the file's owner uid; _link makes the config
# a symlink, or makes its directory one.
capture_reclaim() {
  _mode="$1"
  _euid="$2"
  _owner="${3:-0}"
  _link="${4:-}"
  (
    set +e
    _dir="$(mktemp -d)"
    # shellcheck disable=SC2034 # consumed by the eval'd function
    MONDOO_EUID="$_euid"
    sudo_cmd() { echo "SUDO $*"; }
    red() { echo "RED $1"; }
    stat() { echo "$_owner"; }
    eval "$(sed -n '/^reclaim_macos_user_config()/,/^}$/p' "$INSTALL_SH")"
    mkdir -p "$_dir/home/.config/mondoo"
    _cfg="$_dir/home/.config/mondoo/mondoo.yml"
    if [ "$_mode" != "missing" ]; then
      : > "$_dir/target"
      chmod "$_mode" "$_dir/target"
      case "$_link" in
        file) ln -s "$_dir/target" "$_cfg" ;;
        dir)
          command rm -rf "$_dir/home/.config/mondoo"
          mkdir "$_dir/real"
          mv "$_dir/target" "$_dir/real/mondoo.yml"
          ln -s "$_dir/real" "$_dir/home/.config/mondoo"
          ;;
        *) mv "$_dir/target" "$_cfg" ;;
      esac
    fi
    reclaim_macos_user_config "$_cfg"
    chmod -R u+rwx "$_dir" 2>/dev/null
    command rm -rf "$_dir"
  ) || true
}

# Test 29: a root-owned config the user cannot read (left by an earlier run)
# is handed back without following symlinks. A readable one, a missing one,
# or a root run is left alone.
if [ "$(id -u)" != "0" ]; then
  result=$(capture_reclaim 0000 501)
  assert_contains "unreadable root-owned config is chowned back" "$result" "SUDO chown -h"

  # Test 30: the path is in a directory the user controls, so a symlink on
  # it could point the privileged chown at any root file. Refuse instead.
  result=$(capture_reclaim 0000 501 0 file)
  assert_not_contains "symlinked config is not chowned" "$result" "SUDO"
  assert_contains "symlinked config is reported" "$result" "RED"
  result=$(capture_reclaim 0000 501 0 dir)
  assert_not_contains "config under a symlinked dir is not chowned" "$result" "SUDO"
  result=$(capture_reclaim 0000 501 502)
  assert_not_contains "config owned by another user is not chowned" "$result" "SUDO"
fi
result=$(capture_reclaim 0600 501)
assert_not_contains "readable user config is left alone" "$result" "SUDO"
result=$(capture_reclaim missing 501)
assert_not_contains "missing user config is left alone" "$result" "SUDO"
result=$(capture_reclaim 0000 0)
assert_not_contains "root run does not chown" "$result" "SUDO"

printf '\n==> Results: %d/%d passed' "$PASS" "$TESTS"
if [ "$FAIL" -gt 0 ]; then
  printf ', %d FAILED\n' "$FAIL"
  exit 1
else
  printf '\n'
fi
