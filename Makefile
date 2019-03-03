
.PHONY: build/docker
build/docker:
	DOCKER_BUILDKIT=1 docker build --build-arg VERSION=$(shell cat VERSION) -t mondoolabs/mondoo:$(shell cat VERSION) -t mondoolabs/mondoo:latest .
	docker push mondoolabs/mondoo:$(shell cat VERSION)
	docker push mondoolabs/mondoo:latest