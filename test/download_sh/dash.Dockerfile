# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# The POSIX test of the set. Every other container reaches its shell by
# accident: debian and ubuntu because /bin/sh happens to be dash, the rest
# because /bin/sh is bash. Both are the distribution's choice, not ours, and
# neither fails loudly if it changes -- the coverage would simply stop existing.
#
# dash is named here so that cannot happen. It implements POSIX and very little
# else, which is the point: busybox ash carries enough of bash to let a bashism
# through (that is how the $'\n' in #805 reached production), and bash obviously
# does.
FROM debian:12
RUN apt update -y && apt install -y curl dash
RUN mkdir -p /root/trial
WORKDIR /root/trial
ADD download.sh /root/trial/download.sh
RUN dash /root/trial/download.sh
RUN /root/trial/cnspec version
