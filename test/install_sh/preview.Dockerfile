# Copyright Mondoo, Inc. 2025, 2026
# SPDX-License-Identifier: BUSL-1.1

# The preview channel installs packages as files rather than from a repository,
# because apt and yum each carry a single stream with no notion of a channel.
# That means nothing resolves the dependency graph for us:
#
#   mondoo  Depends: cnspec (>= <version>)
#   cnspec  Depends: mql
#
# So these stages assert what a repository would otherwise have guaranteed --
# that every package in the chain is installed, at the same pre-release version,
# and that no repository was configured behind our back.

FROM ubuntu:22.04 AS preview_ubuntu2204
RUN apt update -y && apt install -y curl
COPY install.sh /run/install.sh
COPY assert_preview.sh /run/assert_preview.sh
RUN /run/install.sh -c preview
RUN /run/assert_preview.sh deb

FROM debian:12 AS preview_debian12
RUN apt update -y && apt install -y curl
COPY install.sh /run/install.sh
COPY assert_preview.sh /run/assert_preview.sh
RUN /run/install.sh -c preview
RUN /run/assert_preview.sh deb

FROM almalinux:9 AS preview_almalinux9
RUN yum install -y --allowerasing curl
COPY install.sh /run/install.sh
COPY assert_preview.sh /run/assert_preview.sh
RUN /run/install.sh -c preview
RUN /run/assert_preview.sh rpm

FROM opensuse/leap:15.4 AS preview_opensuse_leap154
RUN zypper -n install curl
COPY install.sh /run/install.sh
COPY assert_preview.sh /run/assert_preview.sh
RUN /run/install.sh -c preview
RUN /run/assert_preview.sh rpm
