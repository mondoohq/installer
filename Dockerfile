FROM alpine:3.9.4
ARG VERSION=0.11.3
RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*
RUN apk add curl tar rpm
RUN curl https://releases.mondoo.io/mondoo/${VERSION}/mondoo_${VERSION}_linux_amd64.tar.gz | tar -xvzC /usr/local/bin
RUN addgroup -S mondoo && adduser -S -G mondoo mondoo
USER mondoo
CMD mondoo