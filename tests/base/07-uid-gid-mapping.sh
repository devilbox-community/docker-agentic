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

log "Verify NEW_UID and NEW_GID remap devilbox user"
output="$(timeout 60 docker run -e NEW_UID=1234 -e NEW_GID=5678 --rm "${IMAGE}" id devilbox)"
case "${output}" in
	*"uid=1234"*"gid=5678"*) ;;
	*) fail "Expected uid=1234 and gid=5678, got: ${output}" ;;
esac
pass "NEW_UID/NEW_GID remap devilbox user (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
