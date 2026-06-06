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

log "Verify Debian trixie base (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
run "timeout 60 docker run --rm \"${IMAGE}\" sh -c \"grep -q '^ID=debian$' /etc/os-release && grep -q '^VERSION_CODENAME=trixie$' /etc/os-release\""

pass "Debian trixie base image detected"
