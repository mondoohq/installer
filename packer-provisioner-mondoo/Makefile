.PHONY: prep/plugins build/linux build/darwin build/install build

PROVISIONER_BINARY_NAME=packer-provisioner-mondoo
PLUGINS_DIR=~/.packer.d/plugins

prep/plugins:
	mkdir -p ${PLUGINS_DIR}

build/linux:
	GO111MODULE=on CGO_ENABLED=0 GOOS=linux installsuffix=cgo go build -o ./dist/${PROVISIONER_BINARY_NAME}

build/darwin:
	GO111MODULE=on CGO_ENABLED=0 GOOS=darwin installsuffix=cgo go build -o ./dist/${PROVISIONER_BINARY_NAME}

install: prep/plugins
	cp ./dist/${PROVISIONER_BINARY_NAME} ${PLUGINS_DIR}/${PROVISIONER_BINARY_NAME}

test:
	go test -v

test/packer/alpine:
	# use -debug to call step modus
	cd test/alpine3.8 && packer build alpine-3.8-x86_64.json

test/packer/centos:
	# use -debug to call step modus
	cd test/centos7 && packer build centos-7-x86_64.json