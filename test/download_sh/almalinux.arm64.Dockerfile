# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# arm64v8/* is single-arch, so the platform is pinned here rather than left to
# the build host -- the same reason test/install_sh pins its s390x images. Needs
# an arm64 binfmt handler when built on x86:
#   docker run --rm --privileged tonistiigi/binfmt --install arm64
FROM --platform=linux/arm64 arm64v8/almalinux
RUN mkdir -p /root/trial
WORKDIR /root/trial
ADD download.sh /root/trial/download.sh
RUN /root/trial/download.sh
RUN /root/trial/cnspec version