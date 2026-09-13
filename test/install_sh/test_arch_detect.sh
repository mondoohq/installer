#!/bin/sh
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Test that install.sh maps 'uname -m' onto the architecture used in the
# portable release tarball, and that architectures Mondoo does not build for
# are still rejected. Mondoo publishes linux_s390x tarballs, so s390x has to
# map through instead of hitting the "does not support" branch.

# Globals and stub functions below are consumed by the eval'd install.sh functions.
# shellcheck disable=SC2034,SC2317

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SH="${SCRIPT_DIR}/../../install.sh"

PASS=0
FAIL_COUNT=0
TESTS=0

assert_contains() {
  TESTS=$((TESTS + 1))
  _label="$1"; _haystack="$2"; _needle="$3"
  case "$_haystack" in
    *"$_needle"*) PASS=$((PASS + 1)) ;;
    *)
      FAIL_COUNT=$((FAIL_COUNT + 1))
      printf 'FAIL: %s\n  expected to contain: %s\n  got: %s\n' "$_label" "$_needle" "$_haystack" >&2
      ;;
  esac
}

# install.sh runs on source, so the function under test is extracted instead.
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

# set -e aborts the test if the extraction fails
PORTABLE_FN="$(extract_fn install_portable)"

STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT

# 'uname -m' is the only input to the architecture map. Everything else is
# handed to the real uname so the function still sees a real system.
REAL_UNAME="$(command -v uname)"
cat > "$STUB_DIR/uname" <<EOF
#!/bin/sh
if [ "\$1" = "-m" ]; then
  echo "\$FAKE_UNAME_M"
else
  exec "$REAL_UNAME" "\$@"
fi
EOF

# The transfer itself is not under test, so no bytes move and no files land.
cat > "$STUB_DIR/curl" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "$STUB_DIR/tar" <<'EOF'
#!/bin/sh
exit 0
EOF

chmod +x "$STUB_DIR/uname" "$STUB_DIR/curl" "$STUB_DIR/tar"

# portable runs install.sh's install_portable for a given $OS and 'uname -m'
# and returns everything it printed, including the URL it would download.
portable() {
  _os="$1"
  _machine="$2"
  (
    set +e
    cd "$STUB_DIR" || exit 1
    PATH="$STUB_DIR:$PATH"
    FAKE_UNAME_M="$_machine"
    export FAKE_UNAME_M
    OS="$_os"
    MONDOO_BINARY="cnspec"
    MONDOO_PRODUCT_NAME="cnspec"
    UserAgent="test"
    red() { printf '%s\n' "$1"; }
    purple_bold() { printf '%s\n' "$1"; }
    fail() { exit 1; }
    detect_latest_version() { MONDOO_LATEST_VERSION="9.9.9"; }
    detect_portable() { MONDOO_EXECUTABLE="${STUB_DIR}/cnspec"; }
    eval "$PORTABLE_FN"
    install_portable 2>&1
  ) || true
}

printf '==> Testing install.sh architecture detection\n\n'

# IBM Z: mondoo ships linux_s390x, so this must not be rejected
assert_contains "s390x maps to the s390x tarball" \
  "$(portable Debian s390x)" "cnspec_9.9.9_linux_s390x.tar.gz"

# Regression guards for the architectures that already worked
assert_contains "x86_64 maps to amd64" \
  "$(portable Debian x86_64)" "cnspec_9.9.9_linux_amd64.tar.gz"
assert_contains "i386 maps to 386" \
  "$(portable Debian i386)" "cnspec_9.9.9_linux_386.tar.gz"
assert_contains "aarch64 maps to arm64" \
  "$(portable Debian aarch64)" "cnspec_9.9.9_linux_arm64.tar.gz"
assert_contains "aarch64_be maps to arm64" \
  "$(portable Debian aarch64_be)" "cnspec_9.9.9_linux_arm64.tar.gz"
assert_contains "armv8b maps to arm64" \
  "$(portable Debian armv8b)" "cnspec_9.9.9_linux_arm64.tar.gz"
assert_contains "armv8l maps to arm64" \
  "$(portable Debian armv8l)" "cnspec_9.9.9_linux_arm64.tar.gz"

# The architecture map is shared, so $OS picks the system half of the name
assert_contains "macOS selects the darwin tarball" \
  "$(portable macOS aarch64)" "cnspec_9.9.9_darwin_arm64.tar.gz"

# Downloads resolve against the release server
assert_contains "the download URL points at the release server" \
  "$(portable Debian s390x)" "https://releases.mondoo.com/cnspec/9.9.9/cnspec_9.9.9_linux_s390x.tar.gz"

# Architectures with no build are still refused rather than guessed at
assert_contains "an unbuilt architecture is rejected" \
  "$(portable Debian riscv64)" "does not support the (riscv64) architecture"

printf '\n==> Results: %d/%d passed' "$PASS" "$TESTS"
if [ "$FAIL_COUNT" -gt 0 ]; then
  printf ', %d FAILED\n' "$FAIL_COUNT"
  exit 1
else
  printf '\n'
fi
