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

log "Verify devilbox .bashrc sources bash-devilbox snippet"
run "timeout 60 docker run --rm \"${IMAGE}\" grep -q 'bash-devilbox' /home/devilbox/.bashrc"
pass "/home/devilbox/.bashrc sources bash-devilbox (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
