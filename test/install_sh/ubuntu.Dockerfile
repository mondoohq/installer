# Copyright Mondoo, Inc. 2026, 2025, 0
# SPDX-License-Identifier: BUSL-1.1

FROM ubuntu:14.04 as ubuntu1404
RUN apt update -y && apt install -y curl
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version

FROM ubuntu:16.04 as ubuntu1604
RUN apt update -y && apt install -y curl
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version

FROM ubuntu:18.04 as ubuntu1804
RUN apt update -y && apt install -y curl
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version

FROM ubuntu:20.04 as ubuntu2004
RUN apt update -y && apt install -y curl
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version

FROM ubuntu:22.04 as ubuntu2204
RUN apt update -y && apt install -y curl
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version