# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# The ways install.sh declines -H, run against the whole script rather than
# the extracted functions test_hardening.sh covers. A container has no systemd,
# so the paths that apply or remove the settings cannot run here.

# A bad value, or -H without -s enable: both must stop before anything is
# installed.
FROM debian:12 AS hardening_rejected
RUN apt-get update -qq && apt-get install -y -qq curl ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*
COPY install.sh /run/install.sh
RUN set -e; \
    if sh /run/install.sh -s enable -H bogus >/tmp/out 2>&1; then \
      echo "FAIL: install.sh exited 0 for an invalid -H value"; cat /tmp/out; exit 1; \
    fi; \
    grep -q "unknown hardening option 'bogus'" /tmp/out \
      || { echo "FAIL: did not name the invalid value:"; cat /tmp/out; exit 1; }; \
    if sh /run/install.sh -H enable >/tmp/out 2>&1; then \
      echo "FAIL: install.sh exited 0 for -H without -s enable"; cat /tmp/out; exit 1; \
    fi; \
    grep -q -- "-H enable requires -s enable" /tmp/out \
      || { echo "FAIL: did not ask for -s enable:"; cat /tmp/out; exit 1; }; \
    ! command -v cnspec >/dev/null \
      || { echo "FAIL: cnspec was installed before the flags were refused"; exit 1; }; \
    echo "OK: both refused before the install"

# No systemd: the package installs, then the script must stop with an error
# instead of reporting success, and must not have written the drop-in.
FROM debian:12 AS hardening_no_systemd
RUN apt-get update -qq && apt-get install -y -qq curl ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*
COPY install.sh /run/install.sh
RUN set -e; \
    if sh /run/install.sh -s enable -H enable >/tmp/out 2>&1; then \
      echo "FAIL: install.sh exited 0 without systemd"; cat /tmp/out; exit 1; \
    fi; \
    grep -q "only supported on Linux with systemd" /tmp/out \
      || { echo "FAIL: did not say systemd is required:"; cat /tmp/out; exit 1; }; \
    ! grep -q "is ready to go" /tmp/out \
      || { echo "FAIL: reported success after the error"; cat /tmp/out; exit 1; }; \
    [ ! -e /etc/systemd/system/cnspec.service.d/50-cnspec-hardening.conf ] \
      || { echo "FAIL: wrote the drop-in without systemd"; exit 1; }; \
    echo "OK: says systemd is required, exits non-zero"
