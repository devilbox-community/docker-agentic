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

log "Verify /etc/bash-devilbox exists in work image"
run "timeout 60 docker run --rm \"${IMAGE}\" test -f /etc/bash-devilbox"
pass "/etc/bash-devilbox exists (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
