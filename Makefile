ifneq (,)
.error This Makefile requires GNU Make.
endif

# Ensure additional Makefiles are present
MAKEFILES = Makefile.docker Makefile.lint
$(MAKEFILES): URL=https://raw.githubusercontent.com/devilbox/makefiles/master/$(@)
$(MAKEFILES):
	@if ! (curl --fail -sS -o $(@) $(URL) || wget -O $(@) $(URL)); then \
		echo "Error, curl or wget required."; \
		echo "Exiting."; \
		false; \
	fi
include $(MAKEFILES)

# Set default Target
.DEFAULT_GOAL := help


# -------------------------------------------------------------------------------------------------
# Default configuration
# -------------------------------------------------------------------------------------------------
DOCKER_PULL_BASE_IMAGES_IGNORE = devilboxcommunity/agentic-base
# Own vars
TAG        = latest

# Backward-compat: the legacy build-base / build-work aliases accept RELEASE=...
# RELEASE is mapped to VERSION inside those alias targets.
RELEASE   ?= $(VERSION)

# Makefile.docker overwrites
ORG_USER   = devilboxcommunity
NAME       = Agentic
VERSION    = latest
IMAGE      = $(ORG_USER)/agentic
#STAGE      = base
FILE       = $(STAGE)/Dockerfile-$(VERSION)
DIR        = Dockerfiles

ifeq ($(strip $(TAG)),latest)
DOCKER_TAG = $(VERSION)-$(STAGE)
BASE_TAG   = $(VERSION)-base
WORK_TAG   = $(VERSION)-work
else
DOCKER_TAG = $(VERSION)-$(STAGE)-$(TAG)
BASE_TAG   = $(VERSION)-base-$(TAG)
WORK_TAG   = $(VERSION)-work-$(TAG)
endif
ARCH       = linux/amd64


# Makefile.lint overwrites
FL_IGNORES  = .git/,.github/,.idea/,tests/,*.mypy_cache/
SC_IGNORES  = .git/,.github/,.idea/,tests/
JL_IGNORES  = .git/,.github/,.idea/,*.mypy_cache*


# -------------------------------------------------------------------------------------------------
# Default Target
# -------------------------------------------------------------------------------------------------
.PHONY: help
help:
	@echo "lint                                                          Lint project files and repository"
	@echo
	@echo "gen                                                           Generate agentic tool vars and Dockerfiles"
	@echo
	@echo "build STAGE=base|work [VERSION=...] [ARCH=...] [TAG=...]      Build Docker image"
	@echo "rebuild STAGE=base|work [VERSION=...] [ARCH=...] [TAG=...]    Build Docker image without cache"
	@echo "push STAGE=base|work [VERSION=...] [ARCH=...] [TAG=...]       Push Docker image to Docker hub"
	@echo
	@echo "manifest-create [ARCHES=...] [TAG=...]                        Create multi-arch manifest"
	@echo "manifest-push [TAG=...]                                       Push multi-arch manifest"
	@echo
	@echo "test STAGE=base|work [ARCH=...]                               Test built Docker image"
	@echo
	@echo "Deprecated aliases (kept for one release cycle):"
	@echo "  build-base [RELEASE=...]   -> build STAGE=base VERSION=..."
	@echo "  build-work [RELEASE=...]   -> build STAGE=work VERSION=..."
	@echo


# -------------------------------------------------------------------------------------------------
# Overwrite Targets
# -------------------------------------------------------------------------------------------------

# Append additional targets to lint
lint: lint-changelog
lint: lint-ansible

###
### Lightweight yaml lint (uses local yamllint binary; no docker).
### Kept as a standalone target so CI without docker-based linters can still
### invoke yaml validation cheaply.
###
.PHONY: lint-yaml-local
lint-yaml-local:
	@echo "################################################################################"
	@echo "# Lint YAML (local yamllint binary)"
	@echo "################################################################################"
	yamllint -c .yamllint .

###
### Ensures CHANGELOG has an entry
###
.PHONY: lint-changelog
lint-changelog:
	@echo "################################################################################"
	@echo "# Lint Changelog"
	@echo "################################################################################"
	@\
	GIT_CURR_MAJOR="$$( git tag | sort -V | tail -1 | sed 's|\.[0-9]*$$||g' )"; \
	GIT_CURR_MINOR="$$( git tag | sort -V | tail -1 | sed 's|^[0-9]*\.||g' )"; \
	GIT_NEXT_TAG="$${GIT_CURR_MAJOR}.$$(( GIT_CURR_MINOR + 1 ))"; \
	if ! grep -E "^## Release $${GIT_NEXT_TAG}$$" CHANGELOG.md >/dev/null; then \
		echo "[WARN] Missing '## Release $${GIT_NEXT_TAG}' section in CHANGELOG.md"; \
	else \
		echo "[OK] Section '## Release $${GIT_NEXT_TAG}' present in CHANGELOG.md"; \
	fi
	@echo

###
### Ensures Ansible Dockerfile generation is current
###
.PHONY: lint-ansible
lint-ansible: gen-dockerfiles
	@git diff --quiet || { echo "Build Changes"; git diff; git status; false; }


# -------------------------------------------------------------------------------------------------
# Docker Targets
# -------------------------------------------------------------------------------------------------

.PHONY: build
build: check-stage-is-set
build: check-parent-image-exists
build: ARGS+=--build-arg ARCH=$(shell if [ "$(ARCH)" = "linux/amd64" ]; then echo "x86_64"; else echo "aarch64"; fi)
build: docker-arch-build

.PHONY: rebuild
rebuild: check-stage-is-set
rebuild: check-parent-image-exists
rebuild: ARGS+=--build-arg ARCH=$(shell if [ "$(ARCH)" = "linux/amd64" ]; then echo "x86_64"; else echo "aarch64"; fi)
rebuild: docker-arch-rebuild

.PHONY: push
push: check-stage-is-set
push: check-version-is-set
push: docker-arch-push

.PHONY: tag
tag: check-stage-is-set
tag: check-version-is-set
tag:
	docker tag $(IMAGE):$(VERSION)-$(STAGE) $(IMAGE):$(DOCKER_TAG)


# -------------------------------------------------------------------------------------------------
# Save / Load Targets
# -------------------------------------------------------------------------------------------------
.PHONY: save
save: check-stage-is-set
save: check-version-is-set
save: check-current-image-exists
save: docker-save

.PHONY: load
load: docker-load

.PHONY: save-verify
save-verify: save
save-verify: load


# -------------------------------------------------------------------------------------------------
# Manifest Targets
# -------------------------------------------------------------------------------------------------
.PHONY: manifest-create
manifest-create: docker-manifest-create

.PHONY: manifest-push
manifest-push: docker-manifest-push


# -------------------------------------------------------------------------------------------------
# Test Targets
# -------------------------------------------------------------------------------------------------
.PHONY: test
test: check-stage-is-set
test: check-current-image-exists
test: test-integration

.PHONY: test-integration
test-integration:
	bats tests/


# -------------------------------------------------------------------------------------------------
# Generate Targets
# -------------------------------------------------------------------------------------------------

###
### Generate Agentic tool vars and Dockerfiles
###
.PHONY: gen
gen: gen-dockerfiles

# Back-compat alias for the historical `generate` target name.
.PHONY: generate
generate: gen-dockerfiles

.PHONY: gen-dockerfiles
gen-dockerfiles:
	@echo "################################################################################"
	@echo "# Generating Agentic Tool vars"
	@echo "################################################################################"
	./bin/gen-agentic-tools.py
	@echo
	@echo "################################################################################"
	@echo "# Generating Dockerfiles"
	@echo "################################################################################"
	./bin/gen-dockerfiles.sh


# -------------------------------------------------------------------------------------------------
# Backward-compatibility Targets (DEPRECATED — remove after one release cycle)
# -------------------------------------------------------------------------------------------------

.PHONY: build-base
build-base:
	@echo "[DEPRECATED] 'make build-base' is deprecated. Use 'make build STAGE=base [VERSION=latest|stable]' instead." >&2
	@$(MAKE) build STAGE=base VERSION=$(RELEASE)

.PHONY: build-work
build-work:
	@echo "[DEPRECATED] 'make build-work' is deprecated. Use 'make build STAGE=work [VERSION=latest|stable]' instead." >&2
	@$(MAKE) build STAGE=work VERSION=$(RELEASE)


# -------------------------------------------------------------------------------------------------
# HELPER TARGETS
# -------------------------------------------------------------------------------------------------

###
### Ensures the VERSION variable is set
###
.PHONY: check-version-is-set
check-version-is-set:
	@if [ "$(VERSION)" = "" ]; then \
		echo "This make target requires the VERSION variable to be set."; \
		echo "make <target> VERSION="; \
		echo "Exiting."; \
		exit 1; \
	fi

###
### Ensures the STAGE variable is set
###
.PHONY: check-stage-is-set
check-stage-is-set:
	@if [ "$(STAGE)" = "" ]; then \
		echo "This make target requires the STAGE variable to be set."; \
		echo "make <target> STAGE="; \
		echo "Exiting."; \
		exit 1; \
	fi
	@if [ "$(STAGE)" != "base" ] && [ "$(STAGE)" != "work" ]; then \
		echo "Error, Stage can only be one of 'base' or 'work'."; \
		echo "Exiting."; \
		exit 1; \
	fi

###
### Checks if current image exists and is of correct architecture
###
.PHONY: check-current-image-exists
check-current-image-exists: check-stage-is-set
check-current-image-exists:
	@if [ "$$( docker images -q $(IMAGE):$(DOCKER_TAG) )" = "" ]; then \
		>&2 echo "Docker image '$(IMAGE):$(DOCKER_TAG)' was not found locally."; \
		>&2 echo "Either build it first or explicitly pull it from Dockerhub."; \
		>&2 echo "This is a safeguard to not automatically pull the Docker image."; \
		>&2 echo; \
		exit 1; \
	else \
		echo "OK: Image $(IMAGE):$(DOCKER_TAG) exists"; \
	fi; \
	OS="$$( docker image inspect $(IMAGE):$(DOCKER_TAG) --format '{{.Os}}' )"; \
	ARCH="$$( docker image inspect $(IMAGE):$(DOCKER_TAG) --format '{{.Architecture}}' )"; \
	if [ "$${OS}/$${ARCH}" != "$(ARCH)" ]; then \
		>&2 echo "Docker image '$(IMAGE):$(DOCKER_TAG)' has invalid architecture: $${OS}/$${ARCH}"; \
		>&2 echo "Expected: $(ARCH)"; \
		>&2 echo; \
		exit 1; \
	else \
		echo "OK: Image $(IMAGE):$(DOCKER_TAG) is of arch $${OS}/$${ARCH}"; \
	fi

###
### Checks if parent image exists and is of correct architecture
###
### Stage chain for agentic: base -> work
### Only `work` has a parent (`base`). `base` has no parent.
###
.PHONY: check-parent-image-exists
check-parent-image-exists: check-stage-is-set
check-parent-image-exists:
	@if [ "$(STAGE)" = "work" ]; then \
		if [ "$$( docker images -q $(IMAGE):$(BASE_TAG) )" = "" ]; then \
			>&2 echo "Docker image '$(IMAGE):$(BASE_TAG)' was not found locally."; \
			>&2 echo "Either build it first or explicitly pull it from Dockerhub."; \
			>&2 echo "This is a safeguard to not automatically pull the Docker image."; \
			>&2 echo; \
			exit 1; \
		fi; \
		OS="$$( docker image inspect $(IMAGE):$(BASE_TAG) --format '{{.Os}}' )"; \
		ARCH="$$( docker image inspect $(IMAGE):$(BASE_TAG) --format '{{.Architecture}}' )"; \
		if [ "$${OS}/$${ARCH}" != "$(ARCH)" ]; then \
			>&2 echo "Docker image '$(IMAGE):$(BASE_TAG)' has invalid architecture: $${OS}/$${ARCH}"; \
			>&2 echo "Expected: $(ARCH)"; \
			>&2 echo; \
			exit 1; \
		fi; \
	fi;
