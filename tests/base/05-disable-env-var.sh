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

log "Verify AGENTIC_TOOLS_DISABLE removes a default-enabled tool from PATH"
output="$(timeout 60 docker run -e AGENTIC_TOOLS_DISABLE=claude-code --rm "${IMAGE}" sh -c 'which claude || echo NOT_FOUND')"
if [ "${output}" != "NOT_FOUND" ]; then
	fail "Expected claude to be disabled, got: ${output}"
fi
pass "AGENTIC_TOOLS_DISABLE hides claude (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
