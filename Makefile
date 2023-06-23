
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

.PHONY: test/install_sh
test/install_sh:
	cp install.sh test/install_sh && chmod +x test/install_sh/install.sh
	cd test/install_sh && docker build --no-cache -f almalinux.Dockerfile .
	cd test/install_sh && docker build --no-cache -f almalinux.arm64.Dockerfile .
	cd test/install_sh && docker build --no-cache -f amazonlinux2.Dockerfile .
	cd test/install_sh && docker build --no-cache -f debian.Dockerfile .
	cd test/install_sh && docker build --no-cache -f opensuse_leap.Dockerfile .
	cd test/install_sh && docker build --no-cache -f redhat.Dockerfile .
	cd test/install_sh && docker build --no-cache -f ubuntu.Dockerfile .	

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