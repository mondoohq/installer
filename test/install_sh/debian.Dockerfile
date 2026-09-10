# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Debian 9, 10 and 11 are EOL; their repos have moved off the mirrors and
# the default docker images have very little disk space, so we must clean
# apt caches between steps. 9 and 10 are served by archive.debian.org; 11
# needs snapshot.debian.org instead, see the note on that stage.

FROM debian:9 as debian9
RUN printf 'deb http://archive.debian.org/debian stretch main\ndeb http://archive.debian.org/debian-security stretch/updates main\n' > /etc/apt/sources.list && \
    apt -o Acquire::Check-Valid-Until=false update -y && \
    apt install -y ca-certificates curl gnupg && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version

FROM debian:10 as debian10
RUN printf 'deb http://archive.debian.org/debian buster main\ndeb http://archive.debian.org/debian-security buster/updates main\n' > /etc/apt/sources.list && \
    apt -o Acquire::Check-Valid-Until=false update -y && \
    apt install -y ca-certificates curl gnupg && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version

# Bullseye went EOL 2026-08-31 and its security repo is now unusable: the
# Release file expired 2026-09-07 and the pool has been emptied, so packages
# 404. archive.debian.org carries bullseye main and bullseye-updates but no
# bullseye security at all, and this image already ships gpgv from security,
# which the archive's older gnupg refuses to install alongside. The image
# carries commented snapshot.debian.org lines for exactly this case, so swap
# those in and derive the pin from the image rather than hardcoding a
# timestamp that would rot. install.sh runs its own 'apt update', so the
# expiry check is switched off via config rather than a one-off -o flag.
FROM debian:11 as debian11
RUN sed -i -e 's|^deb |#deb |' -e 's|^# deb http://snapshot|deb http://snapshot|' /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    apt update -y && apt install -y curl && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version
