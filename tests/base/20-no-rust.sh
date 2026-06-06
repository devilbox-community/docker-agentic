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

log "Verify rustup and cargo are absent (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
run_fail "timeout 60 docker run --rm \"${IMAGE}\" sh -c \"command -v rustup || command -v cargo\""

pass "rustup and cargo are absent"
