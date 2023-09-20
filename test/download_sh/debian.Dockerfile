# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

FROM debian
# debian does not ship with curl as default
RUN apt update -y && apt install -y curl
RUN mkdir -p /root/trial
WORKDIR /root/trial
ADD download.sh /root/trial/download.sh
RUN /root/trial/download.sh
RUN /root/trial/mondoo version