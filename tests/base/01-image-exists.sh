#!/usr/bin/env bash

set -e
set -u
set -o pipefail

IMAGE="${1}"
ARCH="${2}"
VERSION="${3}"
FLAVOUR="${4}"
TAG="${5}"

# shellcheck disable=SC1091
. "${BASH_SOURCE%/*}/../.lib.sh"

log "Verify docker-agentic image exists locally"
run "docker image inspect \"${IMAGE}\" >/dev/null"
pass "Image exists: ${IMAGE} (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
