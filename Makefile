
.PHONY: build/docker
build/docker:
	DOCKER_BUILDKIT=1 docker build --build-arg VERSION=$(shell cat VERSION) -t mondoo/mondoo:$(shell cat VERSION) -t mondoo/mondoo:latest .
	docker push mondoo/mondoo:$(shell cat VERSION)
	docker push mondoo/mondoo:latest

release/terraform:
	cd terraform-provisioner-mondoo && goreleaser --rm-dist

release/packer:
	cd packer-provisioner-mondoo && goreleaser --rm-dist

test/installsh:
	cp install.sh test/installscript
	cd test/installscript && docker build --no-cache -f centos7.Dockerfile .
	cd test/installscript && docker build --no-cache -f amazonlinux2.Dockerfile .
	cd test/installscript && docker build --no-cache -f debian.Dockerfile .
	cd test/installscript && docker build --no-cache -f ubuntu.Dockerfile .	
	cd test/installscript && docker build --no-cache -f opensuse.Dockerfile .