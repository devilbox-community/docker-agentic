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

log "Verify TIMEZONE updates container timezone"
output="$(timeout 60 docker run -e TIMEZONE=America/Los_Angeles --rm "${IMAGE}" date +%Z)"
case "${output}" in
	PDT|PST) ;;
	*) fail "Expected PDT or PST timezone, got: ${output}" ;;
esac
pass "TIMEZONE sets America/Los_Angeles (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
