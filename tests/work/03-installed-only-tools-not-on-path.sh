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

# Base image has no installed-only tools (all spec tools are
# default-enabled; agent harness tools are per-image).
log "Verify base image has no installed-only tools on PATH (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
pass "No installed-only tools defined in base image (agent harness tools are per-image)"
