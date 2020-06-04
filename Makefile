
.PHONY: build/docker
build/docker:
	DOCKER_BUILDKIT=1 docker build --build-arg VERSION=$(shell cat VERSION) -t mondoolabs/mondoo:$(shell cat VERSION) -t mondoolabs/mondoo:latest .
	docker push mondoolabs/mondoo:$(shell cat VERSION)
	docker push mondoolabs/mondoo:latest

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

.PHONY: test/download_sh
# MONDOO_REGISTRATION_TOKEN="changeme"
test/download_sh:
	cp download.sh test/download_sh
	cd test/download_sh && docker build --no-cache -f alpine.Dockerfile .
	cd test/download_sh && docker build --no-cache -f centos7.Dockerfile .
	cd test/download_sh && docker build --no-cache -f centos7.arm64.Dockerfile .
	cd test/download_sh && docker build --no-cache -f amazonlinux2.Dockerfile .
	cd test/download_sh && docker build --no-cache -f debian.Dockerfile .
	cd test/download_sh && docker build --no-cache -f ubuntu.Dockerfile .	
	cd test/download_sh && docker build --no-cache -f opensuse.Dockerfile .
	# cd test/download_sh && docker build --no-cache --build-arg mondoo_registration_token=${MONDOO_REGISTRATION_TOKEN} -f centos7.Dockerfile .