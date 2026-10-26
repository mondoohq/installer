# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# Mageia ships dnf and no yum.
FROM mageia:9 as mageia9
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version
