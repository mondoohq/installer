#!/bin/sh
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1
#
# Assert that `install.sh -c preview` left a complete, coherent install behind.
#
# Usage: assert_preview.sh deb|rpm
set -eu

PKG_KIND="${1:?usage: assert_preview.sh deb|rpm}"
FAILED=0

fail() {
  echo "FAIL: $*" >&2
  FAILED=1
}

# Report a package's version in canonical semver, whatever the packaging did to
# it. The three formats genuinely differ:
#
#   binary        14.0.0-rc.9
#   deb           14.0.0~rc.9    tilde, so it sorts before the final release
#   mql/cnspec    14.0.0~rc.9    goreleaser keeps the tilde in VERSION
#   mondoo rpm    Version 14.0.0, Release rc.9    nfpm splits the two fields
#
# The last two are both rpms from the same release: the binaries and the
# metapackage are built by different tools, so one release carries two rpm
# conventions.
#
# Normalising here means the assertions below compare like with like, instead of
# encoding one packaging convention and silently passing on the others.
pkg_version() {
  case "${PKG_KIND}" in
    deb)
      dpkg-query --show --showformat '${Version}' "$1" 2>/dev/null | tr '~' '-'
      ;;
    rpm)
      # A stable rpm has Release 1; only a pre-release carries the segment.
      _v="$(rpm -q --qf '%{VERSION}' "$1" 2>/dev/null)" || return 0
      _r="$(rpm -q --qf '%{RELEASE}' "$1" 2>/dev/null)" || return 0
      case "${_r}" in
        ''|1) printf '%s' "${_v}" | tr '~' '-' ;;
        *) printf '%s-%s' "${_v}" "${_r}" | tr '~' '-' ;;
      esac
      ;;
  esac
}

# The version the preview channel actually points at, read the same way
# install.sh reads it. Asserting against this rather than against "something
# with a hyphen in it" is what makes a silent fall back to stable visible.
EXPECTED="$(curl -fsSL https://releases.mondoo.com/mondoo/preview.json \
  | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -n1 \
  | sed 's/.*"\([^"]*\)"$/\1/')"

[ -n "${EXPECTED}" ] || { echo "FAIL: could not read the preview version" >&2; exit 1; }

case "${EXPECTED}" in
  *-*) : ;;  # SemVer 9: a pre-release carries a segment after '-'
  *) fail "preview.json points at ${EXPECTED}, which is not a pre-release" ;;
esac

# 1. Every package in the chain is installed.
#
# mondoo is a metapackage that depends on cnspec, which depends on mql. The
# preview path installs files rather than using a repository, so nothing
# resolves that chain for us -- a partial install is the failure this exists to
# catch, and it would otherwise look like success, because `cnspec version`
# works perfectly well with mondoo missing.
for pkg in mql cnspec mondoo; do
  V="$(pkg_version "${pkg}")"
  if [ -z "${V}" ]; then
    fail "${pkg} is not installed"
  elif [ "${V}" != "${EXPECTED}" ]; then
    fail "${pkg} is ${V}, expected ${EXPECTED}"
  fi
done

# 2. The binaries run, and report that same version.
for bin in mql cnspec; do
  if ! command -v "${bin}" >/dev/null 2>&1; then
    fail "${bin} is not on PATH"
    continue
  fi
  OUT="$("${bin}" version 2>/dev/null || true)"
  case "${OUT}" in
    *"${EXPECTED}"*) : ;;
    *) fail "${bin} reports '${OUT}', expected ${EXPECTED}" ;;
  esac
done

# 3. No repository was configured.
#
# The point of the preview path is that it does not touch apt, yum or zypper,
# which carry stable only. A repository written here would quietly put the
# machine back on the stable line at the next upgrade.
for repo in /etc/apt/sources.list.d/mondoo.list \
            /etc/yum.repos.d/mondoo.repo \
            /etc/zypp/repos.d/mondoo.repo; do
  [ -e "${repo}" ] && fail "${repo} was configured, but preview must not use a repository"
done

if [ "${FAILED}" -ne 0 ]; then
  echo "preview install assertions FAILED" >&2
  exit 1
fi

echo "preview install OK: mql, cnspec and mondoo all at ${EXPECTED}, no repository configured"
