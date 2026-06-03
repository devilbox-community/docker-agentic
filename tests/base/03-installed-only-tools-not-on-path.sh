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

INSTALLED_ONLY_TOOLS=(
	"aider:aider"
	"cline:cline"
	"codebuddy:codebuddy"
	"continue:continue"
	"crush:crush"
	"factory:droid"
	"goose:goose"
	"junie:junie"
	"kilocode:kilo"
	"kimi:kimi"
	"kiro:kiro-cli"
	"llm:llm"
	"multica:multica"
	"openclaude:openclaude"
	"qoder:qodercli"
	"qwen-code:qwen"
	"vibe:vibe"
)

log "Verify installed-only agentic tools are installed but absent from default PATH (${ARCH} ${VERSION} ${FLAVOUR} ${TAG})"
for pair in "${INSTALLED_ONLY_TOOLS[@]}"; do
	slug="${pair%%:*}"
	binary="${pair#*:}"
	log "Checking installed-only tool: ${slug} (${binary})"
	run_fail "timeout 60 docker run --rm \"${IMAGE}\" sh -c \"which ${binary}\""
	run "timeout 60 docker run --rm \"${IMAGE}\" test -x \"/opt/agentic-tools/${slug}/bin/${binary}\""
done

pass "All 17 installed-only tools are absent from PATH and executable under /opt/agentic-tools"
