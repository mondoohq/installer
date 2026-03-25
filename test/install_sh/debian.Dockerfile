# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Debian 9 and 10 are EOL; their repos have moved to archive.debian.org
# and the default docker images have very little disk space, so we must
# clean apt caches between steps.

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

FROM debian:11 as debian11
RUN apt update -y && apt install -y curl
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version
