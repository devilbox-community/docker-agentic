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

log "Verify AGENTIC_TOOLS_ENABLE links selected installed-only tools"
run "timeout 60 docker run -e AGENTIC_TOOLS_ENABLE=kimi,qoder --rm \"${IMAGE}\" sh -c 'which kimi && which qodercli'"
pass "AGENTIC_TOOLS_ENABLE exposes kimi and qodercli (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
