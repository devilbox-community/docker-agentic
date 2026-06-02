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

log "Verify devilbox user can sudo without password"
output="$(timeout 60 docker run -u devilbox --rm "${IMAGE}" sudo whoami)"
if [ "${output}" != "root" ]; then
	fail "Expected sudo whoami to output root, got: ${output}"
fi
pass "devilbox sudo NOPASSWD works (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
