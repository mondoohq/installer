# Copyright Mondoo, Inc. 2026, 2025, 0
# SPDX-License-Identifier: BUSL-1.1

FROM almalinux
ARG mondoo_registration_token
ENV MONDOO_REGISTRATION_TOKEN=$mondoo_registration_token
RUN echo ${MONDOO_REGISTRATION_TOKEN}
RUN mkdir -p /root/trial
WORKDIR /root/trial
ADD download.sh /root/trial/download.sh
RUN /root/trial/download.sh
RUN /root/trial/mondoo version