FROM alpine:3.13
ARG VERSION=4.2.0
ARG PACKAGE="mondoo_${VERSION}_linux_amd64.tar.gz"
ARG BASEURL="https://releases.mondoo.io/mondoo/${VERSION}"
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

# Note: we would prefer to use our own user to ensure the image does not run in root, but this comes with a lot of
# limitations:
# - difficulties with docker volume mounting
# - will not work properly in gcp cloud run (especially with data mounting)
# TODO: revist in future if limitations are still true
# RUN addgroup -S mondoo && adduser -S -G mondoo mondoo
# USER mondoo
ENTRYPOINT [ "mondoo" ]
CMD ["help"]
