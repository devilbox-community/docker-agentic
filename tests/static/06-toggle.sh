#!/usr/bin/env bash
set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck disable=SC1091
. "${CWD}/../.lib.sh"

ROOT="$(repo_root)"
cd "${ROOT}"

print_h_main "agentic toggle script behaviour"

SCRIPT="${ROOT}/Dockerfiles/base/data/startup.1.d/20-agentic-toggle.sh"
DEFAULTS="${ROOT}/agentic_tools/_defaults.yml"

TMPDIR_T="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_T}"' EXIT

export AGENTIC_TOOLS_PREFIX="${TMPDIR_T}/opt/agentic-tools"
export AGENTIC_BIN_DIR="${TMPDIR_T}/usr/local/bin"
export AGENTIC_LOCK_FILE="${TMPDIR_T}/lock"
mkdir -p "${AGENTIC_TOOLS_PREFIX}" "${AGENTIC_BIN_DIR}"
cp "${DEFAULTS}" "${AGENTIC_TOOLS_PREFIX}/_defaults.yml"

ALL_SLUGS="claude-code opencode codex cursor codewhale reasonix hermes openclaw pi-coding-agent gh-copilot gemini aider goose cline continue qwen-code llm crush multica"

install_bin() {
	mkdir -p "${AGENTIC_TOOLS_PREFIX}/${1}/bin"
	printf '#!/bin/sh\necho %s\n' "${2}" >"${AGENTIC_TOOLS_PREFIX}/${1}/bin/${2}"
	chmod +x "${AGENTIC_TOOLS_PREFIX}/${1}/bin/${2}"
}

for slug in ${ALL_SLUGS}; do
	mkdir -p "${AGENTIC_TOOLS_PREFIX}/${slug}/bin"
done
install_bin claude-code claude
install_bin opencode opencode
install_bin codex codex
install_bin cursor cursor-agent
install_bin codewhale codewhale
install_bin reasonix reasonix
install_bin hermes hermes
install_bin openclaw openclaw
install_bin pi-coding-agent pi
install_bin gh-copilot gh
install_bin gemini gemini
install_bin aider aider
install_bin goose goose
install_bin cline cline
install_bin continue continue
install_bin qwen-code qwen
install_bin llm llm
install_bin crush crush
install_bin multica multica

reset_bin() {
	rm -rf "${AGENTIC_BIN_DIR}"
	mkdir -p "${AGENTIC_BIN_DIR}"
}

print_h_sub "toggle script passes bash -n syntax check"
bash -n "${SCRIPT}"

print_h_sub "default invocation enables 11 defaults and disables the rest"
reset_bin
bash "${SCRIPT}"
for bin in claude opencode codex cursor-agent codewhale reasonix hermes openclaw pi gh gemini; do
	assert_symlink "${AGENTIC_BIN_DIR}/${bin}"
done
for bin in aider goose cline continue qwen llm crush multica; do
	assert_not_exists "${AGENTIC_BIN_DIR}/${bin}"
done

print_h_sub "AGENTIC_TOOLS_ENABLE=aider creates aider alongside defaults"
reset_bin
AGENTIC_TOOLS_ENABLE="aider" bash "${SCRIPT}"
assert_symlink "${AGENTIC_BIN_DIR}/aider"
assert_symlink "${AGENTIC_BIN_DIR}/claude"

print_h_sub "AGENTIC_TOOLS_DISABLE=claude-code removes claude symlink"
reset_bin
AGENTIC_TOOLS_DISABLE="claude-code" bash "${SCRIPT}"
assert_not_exists "${AGENTIC_BIN_DIR}/claude"
assert_symlink "${AGENTIC_BIN_DIR}/opencode"

print_h_sub "ENABLE+DISABLE collision: DISABLE wins and warning is logged"
reset_bin
collision_out="$(AGENTIC_TOOLS_ENABLE='aider' AGENTIC_TOOLS_DISABLE='aider' bash "${SCRIPT}" 2>&1)"
echo "${collision_out}" | grep -qi "WARN.*aider.*DISABLE wins" \
	|| { echo "FAIL: collision warning not logged" >&2; echo "${collision_out}" >&2; exit 1; }
assert_not_exists "${AGENTIC_BIN_DIR}/aider"

print_h_sub "re-running the script is idempotent"
reset_bin
AGENTIC_TOOLS_ENABLE="aider" bash "${SCRIPT}"
snapshot1="$(ls -la "${AGENTIC_BIN_DIR}" | awk '{print $NF" "$(NF-2)}' | sort)"
AGENTIC_TOOLS_ENABLE="aider" bash "${SCRIPT}"
snapshot2="$(ls -la "${AGENTIC_BIN_DIR}" | awk '{print $NF" "$(NF-2)}' | sort)"
assert_eq "${snapshot2}" "${snapshot1}" "bin dir changed between runs"

print_h_sub "never removes non-symlink files from bin dir"
reset_bin
real_file="${AGENTIC_BIN_DIR}/aider"
printf '#!/bin/sh\necho real\n' >"${real_file}"
chmod +x "${real_file}"
bash "${SCRIPT}"
[ -f "${real_file}" ] || { echo "FAIL: real file removed" >&2; exit 1; }
[ ! -L "${real_file}" ] || { echo "FAIL: real file replaced by symlink" >&2; exit 1; }

print_h_sub "whitespace and case in env vars are normalised"
reset_bin
AGENTIC_TOOLS_ENABLE="  AIDER ,  GOOSE  " bash "${SCRIPT}"
assert_symlink "${AGENTIC_BIN_DIR}/aider"
assert_symlink "${AGENTIC_BIN_DIR}/goose"
