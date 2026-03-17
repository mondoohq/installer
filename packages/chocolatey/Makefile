SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

PACKAGES := mql cnspec cnquery
CHOCO_IMAGE := chocolatey/choco:latest
CHOCO_SOURCE := https://push.chocolatey.org/

# Forbidden commands that Chocolatey validation rejects in automation scripts
FORBIDDEN_PATTERN := cinst|choco install|choco upgrade|choco uninstall|choco list

.PHONY: all generate validate pack publish clean

ifndef VERSION
  $(error VERSION is required. Usage: make <target> VERSION=13.0.1)
endif

## Generate, validate, and pack all packages
all: generate validate pack

## Generate all packages
generate:
	@for pkg in $(PACKAGES); do \
		echo "======= GENERATING $$pkg ======="; \
		VERSION=$(VERSION) bash $$pkg-generate.sh; \
		if [ -f "$$pkg/tools/chocolateyInstall.ps1" ]; then \
			echo "Install script:"; \
			cat $$pkg/tools/chocolateyInstall.ps1; \
		else \
			echo "Meta-package (no install script)"; \
		fi; \
		echo "--------"; \
	done

## Validate all packages for forbidden choco commands
validate:
	@for pkg in $(PACKAGES); do \
		echo "--- Validating $$pkg ---"; \
		if find "$$pkg/tools" -maxdepth 1 \( -name '*.ps1' -o -name '*.psm1' \) 2>/dev/null | grep -q .; then \
			if grep -riE '($(FORBIDDEN_PATTERN))' $$pkg/tools/*.ps1 $$pkg/tools/*.psm1 2>/dev/null; then \
				echo "FAIL: Found forbidden chocolatey commands in $$pkg automation scripts"; \
				exit 1; \
			fi; \
		fi; \
		echo "PASS: $$pkg validated"; \
	done

## Pack all packages into .nupkg using the choco Docker image
pack:
	@for pkg in $(PACKAGES); do \
		docker run --rm \
			-v "$$(pwd)":/packages \
			$(CHOCO_IMAGE) \
			bash -c "cd /packages/$$pkg && choco pack"; \
		echo "PASS: $$pkg packed"; \
	done

## Publish all packages to Chocolatey (requires CHOCO_API_KEY env var)
publish:
ifndef CHOCO_API_KEY
	$(error CHOCO_API_KEY env var is required for publishing)
endif
	@for pkg in $(PACKAGES); do \
		docker run --rm \
			-v "$$(pwd)":/packages \
			-e CHOCO_API_KEY \
			$(CHOCO_IMAGE) \
			bash -c " \
				cd /packages/$$pkg && \
				choco apikey --key \$$CHOCO_API_KEY --source $(CHOCO_SOURCE) && \
				choco pack && \
				choco push --source=$(CHOCO_SOURCE) \
			"; \
		echo "PASS: $$pkg published"; \
	done

## Remove generated package directories
clean:
	rm -rf $(PACKAGES)
