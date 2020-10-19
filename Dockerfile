FROM alpine:3.12.0
ARG VERSION=1.2.0
RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*
RUN apk add curl tar rpm
RUN curl https://releases.mondoo.io/mondoo/${VERSION}/mondoo_${VERSION}_linux_amd64.tar.gz | tar -xvzC /usr/local/bin

# Note: we would prefer to use our own user to ensure the image does not run in root, but this comes with a lot of
# limitations:
# - difficulties with docker volume mounting
# - will not work properly in gcp cloud run (especially with data mounting)
# TODO: revist in future if limitations are still true
# RUN addgroup -S mondoo && adduser -S -G mondoo mondoo
# USER mondoo
ENTRYPOINT [ "mondoo" ]
CMD ["help"]