#!/bin/sh
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Test that the 'cnspec status' probe in install.sh can never hang the
# installer, and that a completed install is never reported as a failure.
# Regression test for a wedged 'cnspec status' hanging install.sh right after
# "is ready to go!" (mondoohq/installer#694).

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

assert_at_most() {
  TESTS=$((TESTS + 1))
  _label="$1"; _got="$2"; _limit="$3"
  if [ "$_got" -le "$_limit" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL: %s\n  expected at most: %ss\n  got: %ss\n' "$_label" "$_limit" "$_got" >&2
  fi
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
PROBE_FN="$(extract_fn _bounded_status_probe)"
DETECT_FN="$(extract_fn detect_mondoo_registered)"
FINALIZE_FN="$(extract_fn finalize_setup)"

STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT

cat > "$STUB_DIR/ok" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "$STUB_DIR/notregistered" <<'EOF'
#!/bin/sh
exit 1
EOF

# Refuses to die on SIGTERM: this is what made "wait" block forever.
cat > "$STUB_DIR/wedged" <<'EOF'
#!/bin/sh
trap '' TERM
sleep 20
EOF

chmod +x "$STUB_DIR/ok" "$STUB_DIR/notregistered" "$STUB_DIR/wedged"

# probe runs install.sh's detect_mondoo_registered against a stub binary and
# prints the resulting MONDOO_IS_REGISTERED value.
probe() {
  (
    MONDOO_BINARY_PATH="$STUB_DIR/$1"
    MONDOO_STATUS_TIMEOUT=2
    MONDOO_STATUS_GRACE=1
    eval "$PROBE_FN"
    eval "$DETECT_FN"
    detect_mondoo_registered
    echo "$MONDOO_IS_REGISTERED"
  )
}

# probe_bounded is probe() under a watchdog, so a regression fails the test
# instead of hanging it.
probe_bounded() {
  _out="$STUB_DIR/out"
  probe "$1" > "$_out" &
  _probe_pid=$!
  _waited=0
  while kill -0 "$_probe_pid" 2>/dev/null; do
    if [ "$_waited" -ge 15 ]; then
      kill -s KILL "$_probe_pid" 2>/dev/null
      echo "HUNG"
      return
    fi
    sleep 1
    _waited=$((_waited + 1))
  done
  cat "$_out"
}

printf '==> Testing install.sh cnspec status probe\n\n'

assert_equals "successful status means registered" "$(probe ok)" "true"
assert_equals "failed status means not registered" "$(probe notregistered)" "false"

# A wedged status check must time out as "unknown" (not "false", which would
# tell an already-registered asset to register) and must not hang.
started="$(date +%s)"
result="$(probe_bounded wedged)"
elapsed=$(( $(date +%s) - started ))
assert_equals "wedged status times out as unknown" "$result" "unknown"
assert_at_most "wedged status does not hang" "$elapsed" 8

# The killed probe must be reaped, otherwise the shell reports the job itself
# ("install.sh: line N: 123 Killed ...") over the installer's own output.
noise="$( { probe wedged >/dev/null; } 2>&1 )"
assert_equals "timeout path prints no job notice" "$noise" ""

# finalize_setup must not probe again once configure_token has an answer.
result="$(
  MONDOO_IS_REGISTERED=true
  MONDOO_PRODUCT_NAME="mondoo package for mql and cnspec"
  MONDOO_SERVICE=''
  MONDOO_AUTOUPDATER=''
  _exit_ok=false
  configure_token() { :; }
  detect_mondoo_registered() { echo "PROBED"; }
  purple_bold() { :; }
  lightblue_bold() { :; }
  eval "$FINALIZE_FN"
  finalize_setup
)"
assert_equals "finalize_setup reuses a known registration state" "$result" ""

printf '\n==> Results: %d/%d passed' "$PASS" "$TESTS"
if [ "$FAIL" -gt 0 ]; then
  printf ', %d FAILED\n' "$FAIL"
  exit 1
else
  printf '\n'
fi
