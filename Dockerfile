FROM alpine:3.9
ARG VERSION=0.5.0
RUN apk add curl tar rpm
RUN curl https://releases.mondoo.io/mondoo/${VERSION}/mondoo_${VERSION}_linux_amd64.tar.gz | tar -xvzC /usr/local/bin
CMD mondoo