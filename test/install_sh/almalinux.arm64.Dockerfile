# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

FROM arm64v8/almalinux:8 as almalinux8_arm64
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version

FROM arm64v8/almalinux:9 as almalinux9_arm64
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version