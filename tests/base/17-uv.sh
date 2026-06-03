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

log "Verify uv is available at /usr/local/bin (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
run "timeout 60 docker run --rm \"${IMAGE}\" sh -c \"test -x /usr/local/bin/uv && uv --version\""

pass "uv is available"
