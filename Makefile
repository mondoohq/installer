
### This build only caches the containers locally for testing purposes.
.PHONY: docker/build/test
docker/build/test:
	#DOCKER_BUILDKIT=1 docker build --build-arg VERSION=$(shell cat VERSION) -t mondoolabs/mondoo:$(shell cat VERSION) -t mondoolabs/mondoo:latest .
	if docker buildx ls | grep mondoo-builder; then docker buildx rm mondoo-builder; fi
	docker buildx create --name mondoo-builder --driver docker-container --bootstrap --use
	#docker buildx build --build-arg VERSION=$(shell cat VERSION) --platform linux/386,linux/amd64,linux/arm/v7,linux/arm64 -t mondoolabs/mondoo:$(shell cat VERSION) -t mondoolabs/mondoo:latest .
	docker buildx build --build-arg VERSION=$(shell cat VERSION) --platform linux/386 -t mondoolabs/mondoo:$(shell cat VERSION) -t mondoolabs/mondoo:latest . --load
	docker buildx build --build-arg VERSION=$(shell cat VERSION) --platform linux/amd64 -t mondoolabs/mondoo:$(shell cat VERSION) -t mondoolabs/mondoo:latest . --load
	docker buildx build --build-arg VERSION=$(shell cat VERSION) --platform linux/arm/v7 -t mondoolabs/mondoo:$(shell cat VERSION) -t mondoolabs/mondoo:latest . --load
	docker buildx build --build-arg VERSION=$(shell cat VERSION) --platform linux/arm64 -t mondoolabs/mondoo:$(shell cat VERSION) -t mondoolabs/mondoo:latest . --load
	docker tag mondoolabs/mondoo:$(shell cat VERSION) mondoolabs/mondoo:latest
	docker buildx rm mondoo-builder
	docker manifest inspect mondoolabs/mondoo:$(shell cat VERSION)

### This includes --push and will push the manifest directly to the Docker Hub, you must be logged in as a valid user.
.PHONY: docker/build/push
docker/build/push:
	#DOCKER_BUILDKIT=1 docker build --build-arg VERSION=$(shell cat VERSION) -t mondoolabs/mondoo:$(shell cat VERSION) -t mondoolabs/mondoo:latest .
	if docker buildx ls | grep mondoo-builder; then docker buildx rm mondoo-builder; fi
	docker buildx create --name mondoo-builder --driver docker-container --bootstrap --use
	docker buildx build --build-arg VERSION=$(shell cat VERSION) --platform linux/386,linux/amd64,linux/arm/v7,linux/arm64 -t mondoolabs/mondoo:$(shell cat VERSION) -t mondoolabs/mondoo:latest . --push
	docker tag mondoolabs/mondoo:$(shell cat VERSION) mondoolabs/mondoo:latest
	docker buildx rm mondoo-builder
	docker manifest inspect mondoolabs/mondoo:$(shell cat VERSION)

test/shellcheck:
	shellcheck install.sh
	shellcheck download.sh
	shellcheck mdm-scripts/mac/evergreen.sh

## install.sh parameter passing tests
.PHONY: test/install_sh/params
test/install_sh/params:
	sh test/install_sh/test_params.sh

## POSIX sh compatibility checks for install.sh
.PHONY: test/posix
test/posix:
	@echo "==> Checking shebang is #!/bin/sh..."
	head -1 install.sh | grep -q '^#!/bin/sh' || { echo "FAIL: shebang is not #!/bin/sh"; exit 1; }
	@echo "==> Running shellcheck in POSIX sh mode..."
	shellcheck -s sh -S warning install.sh
	@echo "==> Parsing with dash..."
	dash -n install.sh
	@echo "==> All POSIX checks passed."

## Docker-based install.sh tests (existing Dockerfiles)
## Each Dockerfile is a multi-stage build; we must build every stage explicitly
## with --target, otherwise only the last stage runs.
INSTALL_SH_DOCKER_TARGETS := \
	almalinux.Dockerfile:almalinux8 \
	almalinux.Dockerfile:almalinux9 \
	almalinux.arm64.Dockerfile:almalinux8_arm64 \
	almalinux.arm64.Dockerfile:almalinux9_arm64 \
	amazonlinux2.Dockerfile:amazonlinux2 \
	amazonlinux2.Dockerfile:amazonlinux2022 \
	debian.Dockerfile:debian9 \
	debian.Dockerfile:debian10 \
	debian.Dockerfile:debian11 \
	opensuse_leap.Dockerfile:opensuse_leap154 \
	opensuse_leap.Dockerfile:opensuse_tumbleweed \
	redhat.Dockerfile:rhel8 \
	redhat.Dockerfile:rhel9 \
	ubuntu.Dockerfile:ubuntu1404 \
	ubuntu.Dockerfile:ubuntu1604 \
	ubuntu.Dockerfile:ubuntu1804 \
	ubuntu.Dockerfile:ubuntu2004 \
	ubuntu.Dockerfile:ubuntu2204

.PHONY: test/install_sh
test/install_sh:
	cp install.sh test/install_sh && chmod +x test/install_sh/install.sh
	@for entry in $(INSTALL_SH_DOCKER_TARGETS); do \
		dockerfile=$${entry%%:*}; target=$${entry##*:}; \
		echo "==> Building $$dockerfile --target $$target"; \
		docker build --no-cache --target $$target -f test/install_sh/$$dockerfile test/install_sh/ \
		|| exit 1; \
	done

## Per-distro install.sh tests using sh (POSIX) — matches test-released-install-sh.yaml matrix
## These mount the local install.sh and run it under the distro's /bin/sh.
INSTALL_SH_APT_DISTROS := debian:11 debian:12 ubuntu:18.04 ubuntu:20.04 ubuntu:22.04 ubuntu:24.04
INSTALL_SH_YUM_DISTROS := quay.io/centos/centos:stream9 fedora:40 rockylinux:8 rockylinux:9 redhat/ubi8 redhat/ubi9
INSTALL_SH_ZYPPER_DISTROS := registry.suse.com/suse/sle15:15.6

.PHONY: test/install_sh/apt
test/install_sh/apt:
	@for distro in $(INSTALL_SH_APT_DISTROS); do \
		echo "==> Testing install.sh on $$distro (apt)..."; \
		docker run --rm -v "$(CURDIR)":/work:ro $$distro \
			sh -c "apt-get update && apt-get install -y curl && sh /work/install.sh && cnspec version" \
		|| exit 1; \
	done

.PHONY: test/install_sh/yum
test/install_sh/yum:
	@for distro in $(INSTALL_SH_YUM_DISTROS); do \
		echo "==> Testing install.sh on $$distro (yum)..."; \
		docker run --rm -v "$(CURDIR)":/work:ro $$distro \
			sh -c "sh /work/install.sh && cnspec version" \
		|| exit 1; \
	done

.PHONY: test/install_sh/zypper
test/install_sh/zypper:
	@for distro in $(INSTALL_SH_ZYPPER_DISTROS); do \
		echo "==> Testing install.sh on $$distro (zypper)..."; \
		docker run --rm -v "$(CURDIR)":/work:ro $$distro \
			sh -c "zypper -n install curl && sh /work/install.sh && cnspec version" \
		|| exit 1; \
	done

## Test upgrade from cnquery -> mql (extracted from test-released-install-sh.yaml)
UPGRADE_APT_DISTROS := debian:11 debian:12 ubuntu:20.04 ubuntu:22.04 ubuntu:24.04
UPGRADE_YUM_DISTROS := quay.io/centos/centos:stream9 rockylinux:8 rockylinux:9

.PHONY: test/install_sh/upgrade-apt
test/install_sh/upgrade-apt:
	@for distro in $(UPGRADE_APT_DISTROS); do \
		echo "==> Testing cnquery->mql upgrade on $$distro (apt)..."; \
		docker run --rm -v "$(CURDIR)":/work:ro $$distro \
			bash -c "set -e && \
				apt-get update && apt-get install -y curl && \
				echo '==> Installing cnquery...' && \
				MONDOO_PRODUCT_OVERRIDE=cnquery sh /work/install.sh && \
				dpkg -l cnquery && \
				echo '==> Upgrading to mql...' && \
				sh /work/install.sh && \
				mql version && \
				echo '==> SUCCESS'" \
		|| exit 1; \
	done

.PHONY: test/install_sh/upgrade-yum
test/install_sh/upgrade-yum:
	@for distro in $(UPGRADE_YUM_DISTROS); do \
		echo "==> Testing cnquery->mql upgrade on $$distro (yum)..."; \
		docker run --rm -v "$(CURDIR)":/work:ro $$distro \
			bash -c "set -e && \
				echo '==> Installing cnquery...' && \
				MONDOO_PRODUCT_OVERRIDE=cnquery sh /work/install.sh && \
				rpm -q cnquery && \
				echo '==> Upgrading to mql...' && \
				sh /work/install.sh && \
				mql version && \
				echo '==> SUCCESS'" \
		|| exit 1; \
	done

## Run all install.sh tests
.PHONY: test/install_sh/all
test/install_sh/all: test/install_sh/params test/posix test/install_sh test/install_sh/apt test/install_sh/yum test/install_sh/zypper

.PHONY: test/download_sh
# MONDOO_REGISTRATION_TOKEN="changeme"
test/download_sh:
	cp download.sh test/download_sh
	cd test/download_sh && docker build --no-cache -f alpine.Dockerfile .
	cd test/download_sh && docker build --no-cache -f almalinux.Dockerfile .
	cd test/download_sh && docker build --no-cache -f almalinux.arm64.Dockerfile .
	cd test/download_sh && docker build --no-cache -f amazonlinux2.Dockerfile .
	cd test/download_sh && docker build --no-cache -f debian.Dockerfile .
	cd test/download_sh && docker build --no-cache -f ubuntu.Dockerfile .	
	cd test/download_sh && docker build --no-cache -f opensuse.Dockerfile .
	# cd test/download_sh && docker build --no-cache --build-arg mondoo_registration_token=${MONDOO_REGISTRATION_TOKEN} -f centos7.Dockerfile .

.PHONY: test/powershell
test/powershell:
	pwsh -Command "Install-Module -Name PSScriptAnalyzer"
	pwsh -Command "Invoke-ScriptAnalyzer -Path .\install.ps1"
	pwsh -Command "Invoke-ScriptAnalyzer -Path .\download.ps1"
	pwsh -Command "Invoke-ScriptAnalyzer -Path .\powershell/Mondoo.Installer/Mondoo.Installer.psm1"
	pwsh -Command "Test-ModuleManifest -Path ".\powershell\Mondoo.Installer\Mondoo.Installer.psd1""

# Copywrite Check Tool: https://github.com/hashicorp/copywrite
license: license/headers/check

license/headers/check:
	copywrite headers --plan

license/headers/apply:
	copywrite headers
