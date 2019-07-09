
.PHONY: build/docker
build/docker:
	DOCKER_BUILDKIT=1 docker build --build-arg VERSION=$(shell cat VERSION) -t mondoo/mondoo:$(shell cat VERSION) -t mondoo/mondoo:latest .
	docker push mondoo/mondoo:$(shell cat VERSION)
	docker push mondoo/mondoo:latest

release/terraform:
	cd terraform-provisioner-mondoo && goreleaser --rm-dist

release/packer:
	cd packer-provisioner-mondoo && goreleaser --rm-dist

.PHONY: test/install_bash
test/install_bash:
	cp install.sh test/install_bash
	cd test/install_bash && docker build --no-cache -f centos7.Dockerfile .
	cd test/install_bash && docker build --no-cache -f amazonlinux2.Dockerfile .
	cd test/install_bash && docker build --no-cache -f debian.Dockerfile .
	cd test/install_bash && docker build --no-cache -f ubuntu.Dockerfile .	
	cd test/install_bash && docker build --no-cache -f opensuse.Dockerfile .
	cd test/install_bash && docker build --no-cache -f centos7.arm64.Dockerfile .
	cd test/install_bash && docker build --no-cache -f redhat8.Dockerfile .
