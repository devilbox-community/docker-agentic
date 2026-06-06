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

# speckit (specify) is pipx-installed → binary at /usr/local/bin/specify.
# Unlike npm-installed tools, pipx binaries don't have an nvm shadow copy,
# so AGENTIC_TOOLS_DISABLE can fully remove them from PATH.
log "Verify AGENTIC_TOOLS_DISABLE removes a default-enabled tool from PATH"
output="$(timeout 60 docker run -e AGENTIC_TOOLS_DISABLE=speckit --rm "${IMAGE}" sh -c 'which specify || echo NOT_FOUND')"
if [ "${output}" != "NOT_FOUND" ]; then
	fail "Expected specify to be disabled, got: ${output}"
fi
pass "AGENTIC_TOOLS_DISABLE hides specify (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
