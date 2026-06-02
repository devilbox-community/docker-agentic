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

log "Verify base entrypoint helper library can be sourced"
run "timeout 60 docker run --rm \"${IMAGE}\" bash -c 'source /docker-entrypoint.d/100-base-libs.sh && log \"ok\" >/dev/null'"
pass "100-base-libs.sh helper source succeeds (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
