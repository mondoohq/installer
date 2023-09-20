# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

FROM arm64v8/almalinux
RUN mkdir -p /root/trial
WORKDIR /root/trial
ADD download.sh /root/trial/download.sh
RUN /root/trial/download.sh
RUN /root/trial/mondoo version