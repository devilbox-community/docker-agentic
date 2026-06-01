#!/usr/bin/env bats

setup() {
    SCRIPT="${BATS_TEST_DIRNAME}/../Dockerfiles/base/data/startup.1.d/20-agentic-toggle.sh"
    DEFAULTS="${BATS_TEST_DIRNAME}/../agentic_tools/_defaults.yml"
    TMPDIR_T="$(mktemp -d)"
    export AGENTIC_TOOLS_PREFIX="${TMPDIR_T}/opt/agentic-tools"
    export AGENTIC_BIN_DIR="${TMPDIR_T}/usr/local/bin"
    export AGENTIC_LOCK_FILE="${TMPDIR_T}/lock"
    mkdir -p "${AGENTIC_TOOLS_PREFIX}" "${AGENTIC_BIN_DIR}"
    cp "${DEFAULTS}" "${AGENTIC_TOOLS_PREFIX}/_defaults.yml"
    for slug in claude-code opencode codex cursor codewhale reasonix hermes openclaw pi-coding-agent gh-copilot gemini aider goose cline continue qwen-code llm crush multica; do
        mkdir -p "${AGENTIC_TOOLS_PREFIX}/${slug}/bin"
    done
    install_bin() { printf '#!/bin/sh\necho %s\n' "${2}" >"${AGENTIC_TOOLS_PREFIX}/${1}/bin/${2}"; chmod +x "${AGENTIC_TOOLS_PREFIX}/${1}/bin/${2}"; }
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
}

teardown() {
    rm -rf "${TMPDIR_T}"
}

run_toggle() {
    bash "${SCRIPT}"
}

@test "_defaults.yml exists and contains exactly the 11 expected default-ON slugs" {
    [ -f "${DEFAULTS}" ]
    expected="aider:no claude-code:yes codewhale:yes codex:yes continue:no crush:no cursor:yes gemini:yes gh-copilot:yes goose:no hermes:yes cline:no llm:no multica:no openclaw:yes opencode:yes pi-coding-agent:yes qwen-code:no reasonix:yes"
    parsed="$(awk '/^enabled_by_default:/{f=1;next} f{ if($0 ~ /^[[:space:]]*-/){gsub(/^[[:space:]]*-[[:space:]]*/,"",$0);print $0} else if($0 ~ /^[^[:space:]#]/){exit}}' "${DEFAULTS}" | sort | tr '\n' ' ')"
    [ "${parsed}" = "claude-code codewhale codex cursor gemini gh-copilot hermes openclaw opencode pi-coding-agent reasonix " ] \
        || { echo "parsed=[${parsed}]" >&2; false; }
    count=$(printf '%s' "${parsed}" | wc -w | tr -d ' ')
    [ "${count}" = "11" ]
}

@test "toggle script passes bash syntax check" {
    bash -n "${SCRIPT}"
}

@test "default invocation enables the 11 defaults and disables the rest" {
    run_toggle
    for bin in claude opencode codex cursor-agent codewhale reasonix hermes openclaw pi gh gemini; do
        [ -L "${AGENTIC_BIN_DIR}/${bin}" ] || { echo "missing symlink: ${bin}" >&2; false; }
    done
    for bin in aider goose cline continue qwen llm crush multica; do
        [ ! -e "${AGENTIC_BIN_DIR}/${bin}" ] || { echo "should not exist: ${bin}" >&2; false; }
    done
}

@test "AGENTIC_TOOLS_ENABLE=aider creates aider symlink" {
    AGENTIC_TOOLS_ENABLE="aider" run_toggle
    [ -L "${AGENTIC_BIN_DIR}/aider" ]
    [ -L "${AGENTIC_BIN_DIR}/claude" ]
}

@test "AGENTIC_TOOLS_DISABLE=claude-code removes claude symlink" {
    AGENTIC_TOOLS_DISABLE="claude-code" run_toggle
    [ ! -e "${AGENTIC_BIN_DIR}/claude" ]
    [ -L "${AGENTIC_BIN_DIR}/opencode" ]
}

@test "ENABLE+DISABLE collision: DISABLE wins and warning is logged" {
    run bash -c "AGENTIC_TOOLS_PREFIX='${AGENTIC_TOOLS_PREFIX}' AGENTIC_BIN_DIR='${AGENTIC_BIN_DIR}' AGENTIC_LOCK_FILE='${AGENTIC_LOCK_FILE}' AGENTIC_TOOLS_ENABLE='aider' AGENTIC_TOOLS_DISABLE='aider' bash '${SCRIPT}'"
    [ "${status}" -eq 0 ]
    echo "${output}" | grep -qi "WARN.*aider.*DISABLE wins"
    [ ! -e "${AGENTIC_BIN_DIR}/aider" ]
}

@test "re-running the script is idempotent (no state change)" {
    AGENTIC_TOOLS_ENABLE="aider" run_toggle
    snapshot1="$(ls -la "${AGENTIC_BIN_DIR}" | awk '{print $NF" "$(NF-2)}' | sort)"
    AGENTIC_TOOLS_ENABLE="aider" run_toggle
    snapshot2="$(ls -la "${AGENTIC_BIN_DIR}" | awk '{print $NF" "$(NF-2)}' | sort)"
    [ "${snapshot1}" = "${snapshot2}" ]
}

@test "never removes non-symlink files from bin dir" {
    real_file="${AGENTIC_BIN_DIR}/aider"
    printf '#!/bin/sh\necho real\n' >"${real_file}"
    chmod +x "${real_file}"
    run_toggle
    [ -f "${real_file}" ]
    [ ! -L "${real_file}" ]
}

@test "whitespace and case in env vars are normalised" {
    AGENTIC_TOOLS_ENABLE="  AIDER ,  GOOSE  " run_toggle
    [ -L "${AGENTIC_BIN_DIR}/aider" ]
    [ -L "${AGENTIC_BIN_DIR}/goose" ]
}

@test "Dockerfile-base COPYs toggle + oauth-helper into protected /opt/agentic-tools/_entrypoint.d/" {
    for df in Dockerfiles/base/Dockerfile-latest Dockerfiles/base/Dockerfile-stable .ansible/DOCKERFILES/Dockerfile-base.j2; do
        grep -qE 'COPY .*20-agentic-toggle\.sh /opt/agentic-tools/_entrypoint\.d/20-agentic-toggle\.sh' "${df}"
        grep -qE 'COPY .*10-oauth-helper\.sh /opt/agentic-tools/_entrypoint\.d/10-oauth-helper\.sh' "${df}"
    done
}

@test "docker-entrypoint sources protected _entrypoint.d before /startup.1.d" {
    grep -q 'source_dir /opt/agentic-tools/_entrypoint.d' bin/docker-entrypoint.sh
    awk '
        /source_dir \/opt\/agentic-tools\/_entrypoint\.d/ { protected = NR }
        /source_dir \/startup\.1\.d/ { startup = NR }
        END { exit (protected && startup && protected < startup) ? 0 : 1 }
    ' bin/docker-entrypoint.sh
}
