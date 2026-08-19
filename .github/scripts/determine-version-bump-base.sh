#!/usr/bin/env bash
# Determine base branch for the installer's VERSION-file bump PR.
#
# When main's VERSION file has the same major as the incoming release,
# the bump PR opens against main. Otherwise it opens against the v{major}
# support branch (e.g. a v13.35.1 release while main tracks v14 -> v13).
#
# Inputs:
#   $1 (required)   incoming release version (e.g. 13.35.1 — no leading v)
#   $MAIN_VERSION   contents of main's VERSION file. If unset, fetched via
#                   `gh api` using $GH_REPO (owner/repo) and $GH_TOKEN.
#
# Output: prints the base branch to stdout ("main" or "v{major}").
#         Exits non-zero if main's VERSION cannot be read.
set -euo pipefail

RELEASE_VERSION="${1:?release version required as first argument}"

V="${RELEASE_VERSION#v}"
RELEASE_MAJOR="${V%%.*}"

if [ -z "${MAIN_VERSION+set}" ]; then
  # MAIN_VERSION not passed in at all — fetch it. An explicit empty value
  # is respected (and will fail the "Could not read" check below), so tests
  # can exercise the empty-file failure path without touching the network.
  : "${GH_REPO:?GH_REPO or MAIN_VERSION required}"
  MAIN_VERSION=$(gh api "/repos/${GH_REPO}/contents/VERSION?ref=main" --jq '.content' | base64 -d)
fi

# First line, trimmed of whitespace — main's VERSION should just be x.y.z
MAIN_VERSION_TRIMMED=$(printf '%s' "$MAIN_VERSION" | head -1 | tr -d '[:space:]')
MAIN_MAJOR="${MAIN_VERSION_TRIMMED%%.*}"

if [ -z "$MAIN_MAJOR" ]; then
  echo "Could not read main's VERSION file" >&2
  exit 1
fi

if [ "$RELEASE_MAJOR" = "$MAIN_MAJOR" ]; then
  echo main
else
  echo "v${RELEASE_MAJOR}"
fi
