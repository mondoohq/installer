# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

FROM amazonlinux:2 as amazonlinux2
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version

FROM amazonlinux:2022 as amazonlinux2022
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version