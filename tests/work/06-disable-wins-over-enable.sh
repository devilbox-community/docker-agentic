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

log "Verify AGENTIC_TOOLS_DISABLE takes precedence over AGENTIC_TOOLS_ENABLE"
output="$(timeout 60 docker run -e AGENTIC_TOOLS_ENABLE=kimi -e AGENTIC_TOOLS_DISABLE=kimi --rm "${IMAGE}" sh -c 'which kimi || echo NOT_FOUND')"
if [ "${output}" != "NOT_FOUND" ]; then
	fail "Expected disable to win for kimi, got: ${output}"
fi
pass "AGENTIC_TOOLS_DISABLE wins over AGENTIC_TOOLS_ENABLE (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
