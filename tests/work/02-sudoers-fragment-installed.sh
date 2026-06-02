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

log "Verify /etc/sudoers.d/devilbox exists with mode 440"
output="$(timeout 60 docker run --rm "${IMAGE}" sh -c 'test -f /etc/sudoers.d/devilbox && stat -c %a /etc/sudoers.d/devilbox')"
if [ "${output}" != "440" ]; then
	fail "Expected sudoers mode 440, got: ${output}"
fi
pass "/etc/sudoers.d/devilbox mode is 440 (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
