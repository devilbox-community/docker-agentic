#!/bin/bash
#
# 20-agentic-toggle.sh — runtime enable/disable of agentic tool symlinks.
#
# Reads /opt/agentic-tools/_defaults.yml for the default-enabled slug list,
# applies AGENTIC_TOOLS_ENABLE (additive) and AGENTIC_TOOLS_DISABLE (subtractive,
# wins on collision), then synchronises symlinks under /usr/local/bin so the
# enabled set is callable and the disabled set is not.
#
# Idempotent. Safe to re-run. Never deletes non-symlink files. Never removes
# symlinks that point outside the AGENTIC_TOOLS_PREFIX tree.
#
# NOTE on load path: this script is COPY'd into BOTH /startup.1.d/ (user-visible
# reference, may be shadowed by the devilbox cfg/agentic-startup bind-mount) AND
# /opt/agentic-tools/_entrypoint.d/ (protected, not shadowable). The entrypoint
# sources the protected dir BEFORE /startup.1.d so the toggle always runs.
#
# Env overrides (for testing):
#   AGENTIC_TOOLS_PREFIX  default /opt/agentic-tools
#   AGENTIC_BIN_DIR       default /usr/local/bin
#   AGENTIC_LOCK_FILE     default /var/lock/agentic-toggle.lock

set -euo pipefail

: "${AGENTIC_TOOLS_PREFIX:=/opt/agentic-tools}"
: "${AGENTIC_BIN_DIR:=/usr/local/bin}"
: "${AGENTIC_LOCK_FILE:=/var/lock/agentic-toggle.lock}"

_agentic_log() { printf '[agentic-toggle] %s\n' "$*" >&2; }

_agentic_warn() { printf '[agentic-toggle] WARN: %s\n' "$*" >&2; }

_agentic_normalize_csv() {
    printf '%s' "${1:-}" \
        | tr ',' '\n' \
        | tr '[:upper:]' '[:lower:]' \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
        | grep -v '^$' \
        || true
}

_agentic_parse_defaults() {
    local file="${1}"
    [ -r "${file}" ] || { _agentic_warn "defaults file not readable: ${file}"; return 0; }
    awk '
        /^enabled_by_default:/ { in_list = 1; next }
        in_list {
            if ($0 ~ /^[[:space:]]*-[[:space:]]*/) {
                gsub(/^[[:space:]]*-[[:space:]]*/, "", $0)
                gsub(/[[:space:]]+$/, "", $0)
                gsub(/[\"'\'']/, "", $0)
                if ($0 != "") print $0
            } else if ($0 ~ /^[^[:space:]#]/) {
                in_list = 0
            }
        }
    ' "${file}"
}

_agentic_discover_binary() {
    local slug_bin_dir="${1}"
    [ -d "${slug_bin_dir}" ] || return 1
    local entry
    for entry in "${slug_bin_dir}"/*; do
        [ -e "${entry}" ] || continue
        if [ -f "${entry}" ] || [ -L "${entry}" ]; then
            basename "${entry}"
            return 0
        fi
    done
    return 1
}

_agentic_in_list() {
    local needle="${1}"; shift
    local item
    for item in "$@"; do
        [ "${item}" = "${needle}" ] && return 0
    done
    return 1
}

_agentic_toggle_run() {
    local prefix="${AGENTIC_TOOLS_PREFIX}"
    local bin_dir="${AGENTIC_BIN_DIR}"
    local defaults_file="${prefix}/_defaults.yml"

    if [ ! -d "${prefix}" ]; then
        _agentic_log "prefix not present, skipping (${prefix})"
        return 0
    fi

    install -d "${bin_dir}" 2>/dev/null || true

    local defaults_list enable_list disable_list
    defaults_list="$(_agentic_parse_defaults "${defaults_file}" | tr '[:upper:]' '[:lower:]')"
    enable_list="$(_agentic_normalize_csv "${AGENTIC_TOOLS_ENABLE:-}")"
    disable_list="$(_agentic_normalize_csv "${AGENTIC_TOOLS_DISABLE:-}")"

    local -a disable_arr=()
    local slug
    if [ -n "${disable_list}" ]; then
        while IFS= read -r slug; do
            [ -n "${slug}" ] && disable_arr+=("${slug}")
        done <<< "${disable_list}"
    fi

    if [ -n "${enable_list}" ] && [ "${#disable_arr[@]}" -gt 0 ]; then
        while IFS= read -r slug; do
            [ -n "${slug}" ] || continue
            if _agentic_in_list "${slug}" "${disable_arr[@]}"; then
                _agentic_warn "slug '${slug}' appears in both ENABLE and DISABLE; DISABLE wins"
            fi
        done <<< "${enable_list}"
    fi

    local final_set
    final_set="$( { printf '%s\n' "${defaults_list}"; printf '%s\n' "${enable_list}"; } \
        | grep -v '^$' | sort -u )"

    local -a final_arr=()
    if [ -n "${final_set}" ]; then
        while IFS= read -r slug; do
            [ -n "${slug}" ] || continue
            if [ "${#disable_arr[@]}" -gt 0 ] && _agentic_in_list "${slug}" "${disable_arr[@]}"; then
                continue
            fi
            final_arr+=("${slug}")
        done <<< "${final_set}"
    fi

    local slug_dir slug_bin_dir binary target link
    for slug_dir in "${prefix}"/*/; do
        [ -d "${slug_dir}" ] || continue
        slug="$(basename "${slug_dir}")"
        case "${slug}" in _*|.*) continue ;; esac
        slug_bin_dir="${slug_dir}bin"
        [ -d "${slug_bin_dir}" ] || continue
        if ! binary="$(_agentic_discover_binary "${slug_bin_dir}")"; then
            continue
        fi
        target="${slug_bin_dir}/${binary}"
        link="${bin_dir}/${binary}"

        if _agentic_in_list "${slug}" "${final_arr[@]:-}"; then
            if [ ! -e "${target}" ]; then
                _agentic_warn "enable ${slug}: target missing ${target}"
                continue
            fi
            if [ -L "${link}" ] && [ "$(readlink "${link}")" = "${target}" ]; then
                continue
            fi
            ln -sfn "${target}" "${link}"
            _agentic_log "enable ${slug} -> ${link}"
        else
            if [ -L "${link}" ]; then
                local current
                current="$(readlink "${link}")"
                case "${current}" in
                    "${prefix}/"*)
                        rm -f "${link}"
                        _agentic_log "disable ${slug} (removed ${link})"
                        ;;
                    *)
                        _agentic_warn "skip ${slug}: ${link} points outside ${prefix} (${current})"
                        ;;
                esac
            fi
        fi
    done
}

_agentic_toggle_main() {
    local lock_dir
    lock_dir="$(dirname "${AGENTIC_LOCK_FILE}")"
    install -d "${lock_dir}" 2>/dev/null || true

    if command -v flock >/dev/null 2>&1 && [ -w "${lock_dir}" ]; then
        exec 9>"${AGENTIC_LOCK_FILE}" 2>/dev/null || true
        if [ -e /dev/fd/9 ]; then
            flock -w 30 9 || { _agentic_warn "flock failed; continuing without lock"; }
        fi
    fi

    _agentic_toggle_run
}

_agentic_toggle_main

unset -f _agentic_log _agentic_warn _agentic_normalize_csv \
    _agentic_parse_defaults _agentic_discover_binary _agentic_in_list \
    _agentic_toggle_run _agentic_toggle_main 2>/dev/null || true

return 0 2>/dev/null || exit 0
