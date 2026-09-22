# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# The two ways install.sh declines to install, which nothing covered before.
#
# They are different failures and they had collapsed into one message. An OS the
# installer does not know is one thing; an OS it knows perfectly well, whose
# package manager is not installed, is another -- and the second used to report
# the first, which is what #607 was filed as.
#
# Both must exit non-zero. A regression that installs nothing while reporting
# success is worse than either message.

# A supported OS with no AUR helper. configure_archlinux_installer leaves
# MONDOO_INSTALLER empty here and defines mondoo_install to name yay and paru;
# this asserts that message reaches the user rather than a generic one.
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

# An OS install.sh does not support. alpine carries none of the marker files the
# detection chain looks for, so OS is never set and the chain's else branch runs
# -- before the emptiness check, which is why that check was never what reported
# an unsupported system.
FROM alpine:latest AS unsupported_os
COPY install.sh /run/install.sh
RUN set -e; \
    if sh /run/install.sh >/tmp/out 2>&1; then \
      echo "FAIL: install.sh exited 0 on an unsupported OS"; cat /tmp/out; exit 1; \
    fi; \
    grep -q "not yet supported" /tmp/out \
      || { echo "FAIL: did not say the OS is unsupported:"; cat /tmp/out; exit 1; }; \
    echo "OK: says unsupported, exits non-zero"
