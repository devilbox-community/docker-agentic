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

# PS1 is set in /etc/bash-devilbox which is sourced from .bashrc.
# Use bash -ic (interactive) to ensure .bashrc is sourced.
log "Verify interactive PS1 contains agentic marker"
output="$(timeout 60 docker run -u devilbox --rm "${IMAGE}" bash -ic 'echo "$PS1"' 2>/dev/null)"
case "${output}" in
	*agentic*) ;;
	*) fail "Expected PS1 to contain agentic, got: ${output}" ;;
esac
pass "PS1 contains agentic marker (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
