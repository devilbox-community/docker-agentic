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

# Base image ships openspec + speckit as default-enabled.
# openspec is npm-installed → resolves via /opt/nvm/current/bin
# (before /usr/local/bin in PATH). Accept any valid path.
DEFAULT_BINARIES=(openspec specify)
INSTALLED_ONLY_BINARIES=()

log "Verify base-image default-enabled binaries (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
for binary in "${DEFAULT_BINARIES[@]}"; do
	run "timeout 60 docker run --rm \"${IMAGE}\" sh -c \"which ${binary}\""
done

for binary in "${INSTALLED_ONLY_BINARIES[@]}"; do
	run_fail "timeout 60 docker run --rm \"${IMAGE}\" sh -c \"which ${binary}\""
done

pass "Base-image agentic binaries are wired correctly (agent harness tools are per-image)"
