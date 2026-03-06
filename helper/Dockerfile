# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
# Use tmpfs mounts for apt caches so package downloads don't exhaust the
# Docker Desktop VM's overlay filesystem (which has limited free space).
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    apt-get update -qq \
        -o Acquire::Check-Valid-Until=false \
        -o Acquire::AllowInsecureRepositories=true && \
    apt-get install -y -q --no-install-recommends --allow-unauthenticated \
        dpkg-dev rpm make file

WORKDIR /build
COPY . .

ARG VERSION
ENV VERSION=${VERSION}

RUN rm -rf packages mondoo mondoo.deb && make
