#!/usr/bin/env bash
# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1
#
# Every PowerShell file we ship or build with must keep a UTF-8 BOM and CRLF
# line endings.
#
# The BOM is what makes a signed script verify: without it PowerShell reads the
# bytes differently depending on the system's language, the hash stops matching
# the signature, and the script is refused.
# https://learn.microsoft.com/en-us/troubleshoot/windows-client/system-management-components/signed-powershell-script-fails-hash-mismatch
#
# CRLF matters for the same reason -- it is part of the signed bytes -- and
# .gitattributes marks these files `-text` precisely so git never rewrites them.
# That stops git normalising, but nothing stops an editor or a script from
# writing the file back in text mode, which silently converts every CRLF to LF.
# A one-line change then lands as a whole-file diff and the real change becomes
# unreviewable. That is a mistake already made more than once here.
#
# Deliberately not `-e`: every file is checked and every failure reported, so a
# run names all the offenders rather than the first one. The per-file reads are
# guarded individually below, so a command failing cannot be mistaken for a
# file legitimately lacking the property.
set -uo pipefail

# Test fixtures are exempt: they are never signed and never shipped, so neither
# property is load-bearing for them. Matched by shape rather than named one by
# one, so a new Pester file is exempt on the same reasoning as the first
# without a second edit here -- and so the exemption cannot silently widen: it
# reaches Pester files under test/ and nothing else.
is_exempt() {
  case "$1" in
    test/*.Tests.ps1) return 0 ;;
    *) return 1 ;;
  esac
}

fail=0
checked=0

while IFS= read -r f; do
  if is_exempt "$f"; then
    printf '  skip  %s (test fixture)\n' "$f"
    continue
  fi
  checked=$((checked + 1))

  problems=""

  # Guarded so an unreadable file is reported as unreadable rather than as a
  # file without a BOM -- the two need different fixes.
  if ! bom=$(head -c 3 "$f" | od -An -tx1 | tr -d ' \n'); then
    problems="${problems} unreadable"
  elif [ "$bom" != "efbbbf" ]; then
    problems="${problems} missing-utf8-bom"
  fi

  # grep exits 1 for "no match" and 2 for a real error; only 1 means no CRLF.
  grep -qU $'\r' "$f"
  case $? in
    0) ;;
    1) problems="${problems} no-CRLF" ;;
    *) problems="${problems} unreadable" ;;
  esac

  if [ -n "$problems" ]; then
    printf '  FAIL  %s —%s\n' "$f" "$problems"
    fail=1
  else
    printf '  ok    %s\n' "$f"
  fi
done < <(git ls-files '*.ps1' '*.psm1' '*.psd1' | sort)

echo
# A check that matches nothing passes vacuously, which is worse than no check
# at all: rename the scripts or break the glob and this would go green while
# testing nothing.
if [ "$checked" -eq 0 ]; then
  echo "no PowerShell files were checked -- the glob matched nothing, which means this check is not testing anything" >&2
  exit 1
fi

if [ "$fail" -ne 0 ]; then
  cat >&2 <<'MSG'
A PowerShell file lost its UTF-8 BOM or its CRLF line endings.

This is almost always an editor or script writing the file in text mode. Edit
these files in binary mode instead, replacing a substring that contains no
newline:

    b = open(path, 'rb').read()
    open(path, 'wb').write(b.replace(old, new))

Then confirm with:  file <path>
It must still report: UTF-8 (with BOM) text, with CRLF line terminators
MSG
  exit 1
fi

printf 'All %d PowerShell files carry a UTF-8 BOM and CRLF.\n' "$checked"
