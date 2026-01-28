# Copyright Mondoo, Inc. 2026, 2025, 0
# SPDX-License-Identifier: BUSL-1.1

FROM alpine
RUN apk add curl
RUN mkdir -p /trial
WORKDIR /root/trial
ADD download.sh /root/trial/download.sh
RUN sh /root/trial/download.sh
RUN /root/trial/mondoo version