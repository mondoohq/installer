# Copyright (c) Mondoo, Inc.
# SPDX-License-Identifier: BUSL-1.1

FROM almalinux:8 as almalinux8
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version

FROM almalinux:9 as almalinux9
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version