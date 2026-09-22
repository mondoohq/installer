# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# The two ways install.sh declines to install. They are different failures --
# an unknown OS, versus a known one whose package manager is absent -- and the
# second used to report the first, which is what #607 was filed as. Both must
# exit non-zero.

# Known OS, no AUR helper: must name yay/paru, not report a detection failure.
FROM archlinux:latest AS no_package_manager
COPY install.sh /run/install.sh
RUN set -e; \
    if sh /run/install.sh >/tmp/out 2>&1; then \
      echo "FAIL: install.sh exited 0 with no way to install"; cat /tmp/out; exit 1; \
    fi; \
    grep -q "yay or paru" /tmp/out \
      || { echo "FAIL: did not name the missing command:"; cat /tmp/out; exit 1; }; \
    ! grep -q "Cannot determine which installer" /tmp/out \
      || { echo "FAIL: reported detection rather than the missing helper"; cat /tmp/out; exit 1; }; \
    echo "OK: names yay/paru, exits non-zero"

# Unknown OS: alpine has none of the marker files, so the chain's else branch
# runs -- before the emptiness check, which never reported this case.
FROM alpine:latest AS unsupported_os
COPY install.sh /run/install.sh
RUN set -e; \
    if sh /run/install.sh >/tmp/out 2>&1; then \
      echo "FAIL: install.sh exited 0 on an unsupported OS"; cat /tmp/out; exit 1; \
    fi; \
    grep -q "not yet supported" /tmp/out \
      || { echo "FAIL: did not say the OS is unsupported:"; cat /tmp/out; exit 1; }; \
    echo "OK: says unsupported, exits non-zero"
