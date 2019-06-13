
.PHONY: build/docker
build/docker:
	DOCKER_BUILDKIT=1 docker build --build-arg VERSION=$(shell cat VERSION) -t mondoo/mondoo:$(shell cat VERSION) -t mondoo/mondoo:latest .
	docker push mondoo/mondoo:$(shell cat VERSION)
	docker push mondoo/mondoo:latest