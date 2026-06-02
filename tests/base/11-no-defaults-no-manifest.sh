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

log "Verify no generator manifest defaults remain in /opt/agentic-tools"
output="$(timeout 60 docker run --rm "${IMAGE}" sh -c 'ls /opt/agentic-tools/_*.yml 2>/dev/null || echo CLEAN')"
if [ "${output}" != "CLEAN" ]; then
	fail "Expected CLEAN, got: ${output}"
fi
pass "No _*.yml manifests found under /opt/agentic-tools (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
