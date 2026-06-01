#!/usr/bin/env bash
set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck disable=SC1091
. "${CWD}/../.lib.sh"

ROOT="$(repo_root)"
cd "${ROOT}"

print_h_main "gen-agentic-tools.py idempotency"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

print_h_sub "empty tool directory renders empty agentic_tools list"
AGENTIC_TOOL_PATH="${tmpdir}" python3 bin/gen-agentic-tools.py
assert_file_exists .ansible/group_vars/all/work.yml
assert_grep '^agentic_tools: \[\]$' .ansible/group_vars/all/work.yml

first="$(cat .ansible/group_vars/all/work.yml)"

print_h_sub "second run produces identical output (idempotent)"
AGENTIC_TOOL_PATH="${tmpdir}" python3 bin/gen-agentic-tools.py
second="$(cat .ansible/group_vars/all/work.yml)"
assert_eq "${second}" "${first}" "second-run output differs"

print_h_sub "gen-dockerfiles.sh runs cleanly after generator"
run "./bin/gen-dockerfiles.sh >/dev/null"
