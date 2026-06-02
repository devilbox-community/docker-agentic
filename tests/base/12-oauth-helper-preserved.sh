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

log "Verify oauth helper script is preserved in an accepted location"
run "timeout 60 docker run --rm \"${IMAGE}\" test -e /opt/agentic-tools/_entrypoint.d/10-oauth-helper.sh -o -e /startup.1.d/10-oauth-helper.sh"
pass "OAuth helper exists in an accepted location (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
