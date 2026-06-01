ifneq (,)
.error This Makefile requires GNU Make.
endif

.DEFAULT_GOAL := help

ORG_USER ?= devilboxcommunity
IMAGE ?= $(ORG_USER)/agentic
RELEASE ?= latest
ARCH ?= linux/amd64

.PHONY: help
help:
	@echo "gen                                      Generate agentic tool vars and Dockerfiles"
	@echo "generate                                 Alias for gen"
	@echo "build-base [RELEASE=latest|stable]       Build base target"
	@echo "build-work [RELEASE=latest|stable]       Build work image"
	@echo "test                                     Run Bats tests"
	@echo "lint                                     Run yamllint"

.PHONY: gen
gen: generate

.PHONY: generate
generate:
	./bin/gen-dockerfiles.sh

.PHONY: build-base
build-base: generate
	docker build --platform $(ARCH) -f Dockerfiles/base/Dockerfile-$(RELEASE) -t $(IMAGE):base-$(RELEASE) .

.PHONY: build-work
build-work: generate build-base
	docker build --platform $(ARCH) -f Dockerfiles/work/Dockerfile-$(RELEASE) -t $(IMAGE):$(RELEASE) .

.PHONY: test
test:
	bats tests/

.PHONY: lint
lint:
	yamllint -c .yamllint .
