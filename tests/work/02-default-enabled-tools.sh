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

# Base image ships only spec/workflow tools (openspec + speckit).
# Agent harness tools (claude-code, codex, copilot, opencode,
# pi-coding-agent, reasonix) live in their own per-agent images.
# npm-installed tools resolve via /opt/nvm/current/bin (before
# /usr/local/bin in PATH); pipx-installed tools resolve via
# /usr/local/bin.
DEFAULT_ENABLED_TOOLS=(
	"openspec:openspec"
	"speckit:specify"
)

log "Verify default-enabled agentic tools are on PATH (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
for pair in "${DEFAULT_ENABLED_TOOLS[@]}"; do
	slug="${pair%%:*}"
	binary="${pair#*:}"
	log "Checking default-enabled tool: ${slug} (${binary})"
	run "timeout 60 docker run --rm \"${IMAGE}\" sh -c \"which ${binary}\""
done

pass "All 2 default-enabled tools resolve on PATH (agent harness tools are per-image)"
