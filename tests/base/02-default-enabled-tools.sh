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

DEFAULT_ENABLED_TOOLS=(
	"claude-code:claude"
	"codewhale:codewhale"
	"codex:codex"
	"cursor:cursor-agent"
	"gemini:gemini"
	"gh-copilot:gh"
	"hermes:hermes"
	"openclaw:openclaw"
	"opencode:opencode"
	"openspec:openspec"
	"pi-coding-agent:pi"
	"reasonix:reasonix"
	"speckit:specify"
)

log "Verify default-enabled agentic tools are linked on PATH (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
for pair in "${DEFAULT_ENABLED_TOOLS[@]}"; do
	slug="${pair%%:*}"
	binary="${pair#*:}"
	log "Checking default-enabled tool: ${slug} (${binary})"
	path="$(timeout 60 docker run --rm "${IMAGE}" sh -c "which ${binary}")"
	case "${path}" in
		/usr/local/bin/*) ;;
		*) fail "${slug} (${binary}) resolved outside /usr/local/bin: ${path}" ;;
	esac
done

pass "All 13 default-enabled tools resolve under /usr/local/bin"
