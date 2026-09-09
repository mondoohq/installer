# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Covers the apt path on IBM Z against the binary-s390x index of
# https://releases.mondoo.com/debian. The official debian image has no s390x
# variant, so this uses the single-arch s390x/debian image and pins the
# platform rather than leaving it to the build host. Needs an s390x binfmt
# handler:
#   docker run --rm --privileged tonistiigi/binfmt --install s390x

FROM --platform=linux/s390x s390x/debian:12 as debian12_s390x
RUN apt update -y && apt install -y curl
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version
