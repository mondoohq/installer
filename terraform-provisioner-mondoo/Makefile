.PHONY: prep/plugins build/linux build/darwin build/install build test/noop

PLUGINS_DIR=~/.terraform.d/plugins
PROVISIONER_BINARY_NAME=terraform-provisioner-mondoo

prep/plugins:
	mkdir -p ${PLUGINS_DIR}

build:
	GO111MODULE=on CGO_ENABLED=0 installsuffix=cgo go build -o ./dist/${PROVISIONER_BINARY_NAME}
	
install: prep/plugins build
	cp ./dist/${PROVISIONER_BINARY_NAME} ${PLUGINS_DIR}/${PROVISIONER_BINARY_NAME}

test:
	go test -v

CONN=ssh
USER=ec2-user
HOST=52.31.244.47
test/noop:
	pushd ./test/noop && \
	terraform init && \
	rm terraform.tfstat* || true && \
	TF_LOG=ERROR terraform apply -auto-approve -var conn=${CONN} -var user=${USER} -var host=${HOST}  && \
	popd