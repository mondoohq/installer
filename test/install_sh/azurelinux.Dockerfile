# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Azure Linux ships tdnf and no yum, and no /etc/redhat-release. The base image
# carries only ca-certificates-base, which cannot verify releases.mondoo.com;
# a full Azure Linux host has ca-certificates.
FROM mcr.microsoft.com/azurelinux/base/core:3.0 as azurelinux3
RUN tdnf install -y ca-certificates
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version
