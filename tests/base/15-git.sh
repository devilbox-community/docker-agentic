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

log "Verify git is available (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
run "timeout 60 docker run --rm \"${IMAGE}\" git --version"

pass "git is available"
