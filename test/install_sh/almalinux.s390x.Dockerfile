# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Covers the yum path on IBM Z against https://releases.mondoo.com/rpm/s390x.
# AlmaLinux only builds for s390x from 9 onward, so there is no 8 stage here.
# The s390x/* images are single-arch, so the platform is pinned here rather
# than left to the build host. Needs an s390x binfmt handler:
#   docker run --rm --privileged tonistiigi/binfmt --install s390x

FROM --platform=linux/s390x s390x/almalinux:9 as almalinux9_s390x
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version
