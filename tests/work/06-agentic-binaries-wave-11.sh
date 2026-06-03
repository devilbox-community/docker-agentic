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

DEFAULT_BINARIES=(copilot codex codewhale)
INSTALLED_ONLY_BINARIES=(droid qodercli qwen cline codebuddy multica aider)

log "Verify Wave 11 renamed/default binaries (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
for binary in "${DEFAULT_BINARIES[@]}"; do
	run "timeout 60 docker run --rm \"${IMAGE}\" sh -c \"which ${binary} | grep -q '^/usr/local/bin/${binary}$'\""
done

for binary in "${INSTALLED_ONLY_BINARIES[@]}"; do
	run_fail "timeout 60 docker run --rm \"${IMAGE}\" sh -c \"which ${binary}\""
done

run "timeout 60 docker run --rm \"${IMAGE}\" test -x /opt/agentic-tools/factory/bin/droid"
run "timeout 60 docker run --rm \"${IMAGE}\" test -x /opt/agentic-tools/qoder/bin/qodercli"
run "timeout 60 docker run --rm \"${IMAGE}\" test -x /opt/agentic-tools/qwen-code/bin/qwen"

pass "Wave 11 binary names are wired correctly"
