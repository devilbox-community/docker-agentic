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

# Base image has no installed-only tools (all are default-enabled).
# This test verifies the AGENTIC_TOOLS_ENABLE mechanism still works
# by re-enabling a tool that was not disabled.
log "Verify AGENTIC_TOOLS_ENABLE still functions (base image has no installed-only tools)"
run "timeout 60 docker run -e AGENTIC_TOOLS_ENABLE=openspec --rm \"${IMAGE}\" sh -c 'which openspec'"
pass "AGENTIC_TOOLS_ENABLE does not break already-enabled tools (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
