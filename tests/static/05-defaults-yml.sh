#!/usr/bin/env bash
set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck disable=SC1091
. "${CWD}/../.lib.sh"

ROOT="$(repo_root)"
cd "${ROOT}"

print_h_main "_defaults.yml is the authoritative default-on list"

DEFAULTS="${ROOT}/Dockerfiles/base/data/agentic_tools/_defaults.yml"
assert_file_exists "${DEFAULTS}"

print_h_sub "parses to exactly the 11 expected default-ON slugs"
parsed="$(awk '/^enabled_by_default:/{f=1;next} f{ if($0 ~ /^[[:space:]]*-/){gsub(/^[[:space:]]*-[[:space:]]*/,"",$0);print $0} else if($0 ~ /^[^[:space:]#]/){exit}}' "${DEFAULTS}" | sort | tr '\n' ' ')"
expected="claude-code codewhale codex cursor gemini gh-copilot hermes openclaw opencode pi-coding-agent reasonix "
assert_eq "${parsed}" "${expected}" "_defaults.yml default-ON list"

count="$(printf '%s' "${parsed}" | wc -w | tr -d ' ')"
assert_eq "${count}" "11" "default-ON count"
