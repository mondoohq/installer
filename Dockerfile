# Copyright Mondoo, Inc. 2026, 2025, 0
# SPDX-License-Identifier: BUSL-1.1

# Mondoo Multi-Architecture Container Dockerfile
# 
# To build root images with BuildX:   docker buildx build --build-arg VERSION=5.21.0 --platform 
#             linux/386,linux/amd64,linux/arm/v7,linux/arm64 --target root -t mondoolabs/mondoo:5.21.0 . --push
#
# To build rootless images with BuildX:   docker buildx build --build-arg VERSION=5.21.0 --platform 
#             linux/386,linux/amd64,linux/arm/v7,linux/arm64 --target rootless -t mondoolabs/mondoo:5.21.0 . --push

ARG VERSION
FROM docker.io/mondoo/cnspec:${VERSION} AS root

RUN ln -s /usr/local/bin/cnspec /usr/local/bin/mondoo

ENTRYPOINT [ "cnspec" ]
CMD ["help"]

# Rootless version of the container
FROM root AS rootless

RUN addgroup -S mondoo && adduser -S -G mondoo mondoo
USER mondoo

