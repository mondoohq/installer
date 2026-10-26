# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# OpenCloudOS is rpm based but ships no /etc/redhat-release.
FROM opencloudos/opencloudos9-minimal as opencloudos9
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version
