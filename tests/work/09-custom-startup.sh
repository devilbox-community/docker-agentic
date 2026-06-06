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

log "Verify custom startup scripts from /startup.1.d are executed"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
printf '%s\n' '#!/usr/bin/env bash' 'echo HELLO' > "${tmpdir}/99-hello.sh"
chmod +x "${tmpdir}/99-hello.sh"

output="$(timeout 60 docker run -v "${tmpdir}:/startup.1.d:ro" --rm "${IMAGE}" true)"
case "${output}" in
	*HELLO*) ;;
	*) fail "Expected custom startup output HELLO, got: ${output}" ;;
esac
pass "Custom startup scripts execute (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
