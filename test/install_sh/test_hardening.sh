#!/bin/sh
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Test the -H flag of install.sh, which turns the hardened systemd settings for
# the cnspec service on or off. The hardening() function is extracted from
# install.sh and run against a scratch directory standing in for /, with
# systemctl stubbed, so the assertions see both the commands that would be run
# and the files they leave behind.

# Globals and stub functions below are consumed by the eval'd install.sh functions.
# shellcheck disable=SC2034,SC2317,SC2329

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

# install.sh runs on source, so the functions under test are extracted instead.
# The closing brace is anchored to its own line and the result is validated, so
# a reshaped function fails loudly here rather than eval'ing a partial slice.
extract_fn() {
  _snippet="$(sed -n "/^$1()/,/^}\$/p" "$INSTALL_SH")"
  if [ -z "$_snippet" ] || [ "$(printf '%s\n' "$_snippet" | tail -1)" != "}" ]; then
    printf 'ERROR: could not extract %s() from %s\n' "$1" "$INSTALL_SH" >&2
    return 1
  fi
  printf '%s\n' "$_snippet"
}

# set -e aborts the test if any extraction fails
HARDENING_FN="$(extract_fn hardening)"
FINALIZE_FN="$(extract_fn finalize_setup)"

# The flag parsing is top-level code: everything from the getopts loop up to
# the next section, which includes the "-H requires -s enable" check.
PARSE_SNIPPET="$(sed -n '/^while getopts/,/^# Proxy$/p' "$INSTALL_SH")"
if [ "$(printf '%s\n' "$PARSE_SNIPPET" | tail -1)" != "# Proxy" ]; then
  printf 'ERROR: could not extract the flag parsing from %s\n' "$INSTALL_SH" >&2
  exit 1
fi

SRC="/usr/share/cnspec/systemd/hardening.conf"
DROPIN_DIR="/etc/systemd/system/cnspec.service.d"
DROPIN="${DROPIN_DIR}/50-cnspec-hardening.conf"

# ROOT stands in for /. The two paths are fixed names other tools rely on, so
# they are first asserted as written and only then pointed into ROOT.
ROOT="$(mktemp -d)"
LOG="${ROOT}/commands.log"
trap 'rm -rf "$ROOT"' EXIT

HARDENING_FN_ROOTED="$(printf '%s\n' "$HARDENING_FN" |
  sed -e "s#\"/usr/share/cnspec#\"${ROOT}/usr/share/cnspec#" -e "s#\"/etc/systemd#\"${ROOT}/etc/systemd#")"

# reset_root empties ROOT; with "packaged" it also adds the settings file the
# way the deb and rpm packages ship it.
reset_root() {
  rm -rf "${ROOT:?}/usr" "${ROOT:?}/etc" "$LOG"
  : > "$LOG"
  if [ "${1:-}" = "packaged" ]; then
    mkdir -p "${ROOT}$(dirname "$SRC")"
    printf '[Service]\nMemoryMax=1G\n' > "${ROOT}${SRC}"
    # Stricter than the 0644 the drop-in must end up with
    chmod 0600 "${ROOT}${SRC}"
  fi
}

# commands prints what was run through sudo_cmd, with ROOT stripped again.
commands() {
  sed "s#${ROOT}##g" "$LOG"
}

# run_hardening runs install.sh's hardening() for -H <$1>. $2 is what
# /proc/1/comm reports (default systemd), $3 the exit code of systemctl.
run_hardening() {
  (
    MONDOO_HARDENING="$1"
    _pid1="${2-systemd}"
    _systemctl_rc="${3:-0}"
    cat() { echo "$_pid1"; }
    systemctl() { return "$_systemctl_rc"; }
    sudo_cmd() { echo "$*" >> "$LOG"; "$@"; }
    purple_bold() { :; }
    red() { printf '%s\n' "$1"; }
    fail() { exit 1; }
    eval "$HARDENING_FN_ROOTED"
    hardening
  )
}

# run_finalize runs install.sh's finalize_setup with the real hardening() and
# prints one line per command and step, so their order can be asserted.
run_finalize() {
  (
    MONDOO_HARDENING="$1"
    _systemctl_rc="${2:-0}"
    MONDOO_SERVICE='enable'
    MONDOO_AUTOUPDATER=''
    MONDOO_IS_REGISTERED=true
    MONDOO_PRODUCT_NAME="mondoo package for mql and cnspec"
    _exit_ok=false
    cat() { echo "systemd"; }
    systemctl() { return "$_systemctl_rc"; }
    sudo_cmd() { echo "run: $*"; "$@"; }
    configure_token() { echo "step: configure_token"; }
    service() { echo "step: service"; }
    purple_bold() { case "$1" in *"is ready to go!") echo "step: ready to go" ;; esac; }
    lightblue_bold() { :; }
    red() { printf '%s\n' "$1"; }
    fail() { exit 1; }
    eval "$HARDENING_FN_ROOTED"
    eval "$FINALIZE_FN"
    finalize_setup
  ) | sed "s#${ROOT}##g"
}

# parse runs install.sh's flag parsing with the given arguments in a shell of
# its own and prints its output, followed by the exit code.
parse() {
  _rc=0
  sh -c "print_usage() { echo usage; }
fail() { exit 1; }
MONDOO_SERVICE=''
MONDOO_HARDENING=''
${PARSE_SNIPPET}
echo \"parsed: service=\${MONDOO_SERVICE} hardening=\${MONDOO_HARDENING}\"" sh "$@" 2>&1 || _rc=$?
  echo "exit=${_rc}"
}

printf '==> Testing install.sh -H: fixed paths\n\n'

assert_contains "source path is the packaged one" "$HARDENING_FN" "hardening_src=\"${SRC}\""
assert_contains "drop-in directory is the service's" "$HARDENING_FN" "hardening_dir=\"${DROPIN_DIR}\""
assert_contains "drop-in file name is fixed" "$HARDENING_FN" "/50-cnspec-hardening.conf\""

printf '==> Testing install.sh -H enable\n\n'

reset_root packaged
rc=0
out="$(run_hardening enable)" || rc=$?
assert_equals "enable succeeds" "$rc" "0"
assert_equals "enable runs exactly these commands" "$(commands)" "mkdir -p ${DROPIN_DIR}
cp ${SRC} ${DROPIN}
chmod 0644 ${DROPIN}
systemctl daemon-reload"
assert_equals "drop-in has the packaged content" "$(command cat "${ROOT}${DROPIN}")" "$(command cat "${ROOT}${SRC}")"
# shellcheck disable=SC2012 # only the mode column is read
assert_equals "drop-in is mode 0644" "$(ls -l "${ROOT}${DROPIN}" | cut -c1-10)" "-rw-r--r--"
assert_equals "drop-in is a copy, not a symlink" "$([ -L "${ROOT}${DROPIN}" ] && echo symlink || echo file)" "file"
assert_equals "the packaged file is left in place" "$([ -f "${ROOT}${SRC}" ] && echo kept || echo moved)" "kept"
assert_not_contains "enable does not restart the service" "$(commands)" "restart"

# A second run on a host that already has the drop-in replaces it.
printf 'stale\n' > "${ROOT}${DROPIN}"
rc=0
out="$(run_hardening enable)" || rc=$?
assert_equals "enable over an existing drop-in succeeds" "$rc" "0"
assert_equals "enable refreshes an existing drop-in" "$(command cat "${ROOT}${DROPIN}")" "$(command cat "${ROOT}${SRC}")"

printf '==> Testing install.sh -H enable: missing settings file\n\n'

reset_root
rc=0
out="$(run_hardening enable)" || rc=$?
assert_equals "missing settings file exits non-zero" "$rc" "1"
assert_contains "missing settings file names the path" "$out" "$SRC"
assert_contains "missing settings file names the required version" "$out" "cnspec 14.12.0 or newer"
assert_contains "missing settings file names the package types" "$out" "deb or rpm package"
assert_equals "missing settings file runs no commands" "$(commands)" ""
assert_equals "missing settings file creates no directory" "$([ -e "${ROOT}${DROPIN_DIR}" ] && echo created || echo absent)" "absent"

printf '==> Testing install.sh -H: no systemd\n\n'

reset_root packaged
rc=0
out="$(run_hardening enable init)" || rc=$?
assert_equals "enable without systemd exits non-zero" "$rc" "1"
assert_contains "enable without systemd says why" "$out" "only supported on Linux with systemd"
assert_equals "enable without systemd runs no commands" "$(commands)" ""

# /proc/1/comm does not exist on macOS, so the lookup comes back empty.
rc=0
out="$(run_hardening enable '')" || rc=$?
assert_equals "enable without /proc exits non-zero" "$rc" "1"
assert_contains "enable without /proc says why" "$out" "only supported on Linux with systemd"

printf '==> Testing install.sh -H disable\n\n'

reset_root packaged
run_hardening enable >/dev/null
printf '[Service]\nNice=5\n' > "${ROOT}${DROPIN_DIR}/10-other.conf"
: > "$LOG"
rc=0
out="$(run_hardening disable)" || rc=$?
assert_equals "disable succeeds" "$rc" "0"
assert_equals "disable runs exactly these commands" "$(commands)" "rm -f ${DROPIN}
systemctl daemon-reload"
assert_equals "disable removes the drop-in" "$([ -e "${ROOT}${DROPIN}" ] && echo present || echo removed)" "removed"
assert_equals "disable leaves other drop-ins alone" "$(command cat "${ROOT}${DROPIN_DIR}/10-other.conf")" "[Service]
Nice=5"
assert_equals "disable leaves the packaged file alone" "$([ -f "${ROOT}${SRC}" ] && echo kept || echo removed)" "kept"

# Nothing to remove is not an error: the host ends up in the requested state.
reset_root
rc=0
out="$(run_hardening disable)" || rc=$?
assert_equals "disable without a drop-in succeeds" "$rc" "0"
assert_contains "disable without a drop-in still reloads" "$(commands)" "systemctl daemon-reload"

printf '==> Testing install.sh -H: a failing command stops the script\n\n'

reset_root packaged
rc=0
out="$(run_hardening enable systemd 1)" || rc=$?
assert_equals "enable with a failing daemon-reload exits non-zero" "$rc" "1"
assert_contains "enable with a failing daemon-reload says so" "$out" "Failed to enable"

rc=0
out="$(run_hardening disable systemd 1)" || rc=$?
assert_equals "disable with a failing daemon-reload exits non-zero" "$rc" "1"
assert_contains "disable with a failing daemon-reload says so" "$out" "Failed to disable"

# A failing copy must not go on to reload: remove the write bit from the
# directory. Root ignores it, so this only tells anything as a regular user.
if [ "$(id -u)" != "0" ]; then
  reset_root packaged
  mkdir -p "${ROOT}${DROPIN_DIR}"
  chmod 0555 "${ROOT}${DROPIN_DIR}"
  rc=0
  out="$(run_hardening enable 2>/dev/null)" || rc=$?
  chmod 0755 "${ROOT}${DROPIN_DIR}"
  assert_equals "enable with a failing copy exits non-zero" "$rc" "1"
  assert_not_contains "enable with a failing copy does not reload" "$(commands)" "daemon-reload"
fi

printf '==> Testing install.sh -H in finalize_setup\n\n'

reset_root packaged
out="$(run_finalize enable)"
assert_equals "-H enable runs before registration and the service step" "$out" "run: mkdir -p ${DROPIN_DIR}
run: cp ${SRC} ${DROPIN}
run: chmod 0644 ${DROPIN}
run: systemctl daemon-reload
step: configure_token
step: service
step: ready to go"

reset_root packaged
out="$(run_finalize enable 1)"
assert_contains "a failing step reports the failure" "$out" "Failed to enable"
assert_not_contains "a failing step stops before registration" "$out" "step: configure_token"
assert_not_contains "a failing step stops before the service step" "$out" "step: service"
assert_not_contains "a failing step never reports success" "$out" "step: ready to go"

reset_root
out="$(run_finalize enable)"
assert_contains "a missing settings file reports the requirement" "$out" "cnspec 14.12.0 or newer"
assert_not_contains "a missing settings file stops before registration" "$out" "step: configure_token"
assert_not_contains "a missing settings file never reports success" "$out" "step: ready to go"

# Without -H the new step runs nothing, even where the settings file exists.
reset_root packaged
out="$(run_finalize '')"
assert_equals "no -H runs no hardening command" "$out" "step: configure_token
step: service
step: ready to go"
assert_equals "no -H leaves the drop-in directory alone" "$([ -e "${ROOT}${DROPIN_DIR}" ] && echo created || echo absent)" "absent"

printf '==> Testing install.sh -H flag parsing\n\n'

out="$(parse -s enable -H enable)"
assert_contains "-s enable -H enable is accepted" "$out" "parsed: service=enable hardening=enable"
assert_contains "-s enable -H enable exits zero" "$out" "exit=0"

out="$(parse -H disable -s enable)"
assert_contains "-H disable is accepted in any order" "$out" "parsed: service=enable hardening=disable"

out="$(parse -s enable -H bogus)"
assert_contains "an invalid value is named" "$out" "unknown hardening option 'bogus', expected enable or disable"
assert_contains "an invalid value exits non-zero" "$out" "exit=1"
assert_not_contains "an invalid value stops the script" "$out" "parsed:"

out="$(parse -H enable)"
assert_contains "-H without -s is refused" "$out" "-H enable requires -s enable"
assert_contains "-H without -s exits non-zero" "$out" "exit=1"
assert_not_contains "-H without -s stops the script" "$out" "parsed:"

out="$(parse -H disable)"
assert_contains "-H disable without -s is refused" "$out" "-H disable requires -s enable"

out="$(parse -s other -H enable)"
assert_contains "-H with another -s value is refused" "$out" "-H enable requires -s enable"

out="$(parse -s enable)"
assert_contains "no -H leaves the setting empty" "$out" "parsed: service=enable hardening="
assert_contains "no -H exits zero" "$out" "exit=0"

out="$(parse)"
assert_contains "no flags at all still parses" "$out" "parsed: service= hardening="

printf '\n==> Results: %d/%d passed' "$PASS" "$TESTS"
if [ "$FAIL" -gt 0 ]; then
  printf ', %d FAILED\n' "$FAIL"
  exit 1
else
  printf '\n'
fi
