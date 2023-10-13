#!/bin/bash
# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

cnspec logout --force
rm /etc/opt/mondoo/mondoo.yml

# use specific token for registration
export MONDOO_REGISTRATION_TOKEN="TOKEN HERE"

bash -c "$(curl -sSL https://install.mondoo.com/sh)"

cnspec login --token "${MONDOO_REGISTRATION_TOKEN}" --config /etc/opt/mondoo/mondoo.yml
systemctl enable --now cnspec.service

# Detect operating system
# -----------------------
# Store detected value in $OS
KNOWN_DISTRIBUTION="(RedHat|Red Hat|CentOS|Debian|Ubuntu|openSUSE|Amazon|SUSE|Arch Linux|AlmaLinux|Rocky Linux|Fedora)"
DISTRIBUTION="$(
    lsb_release -d 2>/dev/null | grep -Eo "$KNOWN_DISTRIBUTION" ||
        grep -m1 -Eo "$KNOWN_DISTRIBUTION" /etc/os-release 2>/dev/null ||
        grep -Eo "$KNOWN_DISTRIBUTION" /etc/issue 2>/dev/null ||
        uname -s
)"

if [ "$DISTRIBUTION" = "Darwin" ]; then
    echo "macos is not supported"
    exit 1
elif [ -f /etc/debian_version ] || [ "$DISTRIBUTION" == "Debian" ] || [ "$DISTRIBUTION" == "Ubuntu" ]; then
    echo $'#!/bin/sh\napt update && apt --only-upgrade install -y mondoo' >/etc/cron.weekly/mondoo-update
elif [ -f /etc/redhat-release ] || [ "$DISTRIBUTION" == "RedHat" ] || [ "$DISTRIBUTION" == "CentOS" ] || [ "$DISTRIBUTION" == "Amazon" ] || [ "$DISTRIBUTION" == "AlmaLinux" ] || [ "$DISTRIBUTION" == "Rocky Linux" ] || [ "$DISTRIBUTION" == "Fedora" ]; then
    echo $'#!/bin/sh\nyum update -y mondoo' >/etc/cron.weekly/mondoo-update
elif [ -f /etc/photon-release ] || [ "$DISTRIBUTION" == "Photon" ]; then
    echo $'#!/bin/sh\nyum update -y mondoo' >/etc/cron.weekly/mondoo-update
# openSUSE and SUSE use /etc/SuSE-release
elif [ -f /etc/SuSE-release ] || [ "$DISTRIBUTION" == "SUSE" ] || [ "$DISTRIBUTION" == "openSUSE" ]; then
    echo $'#!/bin/sh\nzypper -n update mondoo' >/etc/cron.weekly/mondoo-update
elif [ -f /etc/arch-release ] || [ "$DISTRIBUTION" == "Arch" ]; then
    echo "Arch is not supported"
    exit 1
fi

chmod a+x /etc/cron.weekly/mondoo-update
