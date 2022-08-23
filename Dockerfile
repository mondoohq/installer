# Mondoo Multi-Architecture Container Dockerfile
# 
# To build root images with BuildX:   docker buildx build --build-arg VERSION=5.21.0 --platform 
#             linux/386,linux/amd64,linux/arm/v7,linux/arm64 --target root -t mondoolabs/mondoo:5.21.0 . --push
#
# To build rootless images with BuildX:   docker buildx build --build-arg VERSION=5.21.0 --platform 
#             linux/386,linux/amd64,linux/arm/v7,linux/arm64 --target rootless -t mondoolabs/mondoo:5.21.0 . --push

FROM alpine:3.15 AS root
ARG VERSION

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

ARG BASEURL="https://releases.mondoo.com/mondoo/${VERSION}"
ARG PACKAGE="mondoo_${VERSION}_${TARGETOS}_${TARGETARCH}${TARGETVARIANT}.tar.gz"

RUN apk update &&\
    apk add ca-certificates wget tar &&\
    wget --quiet --output-document=SHA256SUMS ${BASEURL}/checksums.linux.txt &&\
    wget --quiet --output-document=${PACKAGE} ${BASEURL}/${PACKAGE} &&\
    cat SHA256SUMS | grep "${PACKAGE}" | sha256sum -c - &&\
    tar -xzC /usr/local/bin -f ${PACKAGE} &&\
    /usr/local/bin/mondoo version &&\
    rm -f ${PACKAGE} SHA256SUMS &&\
    apk del wget tar --quiet &&\
    rm -rf /var/cache/apk/*
 
ENTRYPOINT [ "mondoo" ]
CMD ["help"]

# Rootless version of the container
FROM root AS rootless

RUN addgroup -S mondoo && adduser -S -G mondoo mondoo
USER mondoo

