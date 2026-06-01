#!/usr/bin/env bash

set -euo pipefail

MY_USER="${MY_USER:-devilbox}"
MY_GROUP="${MY_GROUP:-devilbox}"
DEBUG_ENTRYPOINT="${DEBUG_ENTRYPOINT:-0}"

log() {
  local level="${1}"
  local message="${2}"
  if [ "${level}" = "err" ] || [ "${level}" = "warn" ] || [ "${DEBUG_ENTRYPOINT}" != "0" ]; then
    printf '[%s] %s\n' "${level}" "${message}" >&2
  fi
}

isint() {
  test -n "${1##*[!0-9]*}"
}

change_uid_gid() {
  if [ "$(id -u)" != "0" ]; then
    return 0
  fi

  if [ -n "${NEW_GID:-}" ]; then
    isint "${NEW_GID}" || { log err "NEW_GID is not an integer: ${NEW_GID}"; exit 1; }
    groupmod -g "${NEW_GID}" "${MY_GROUP}" 2>/dev/null || true
  fi

  if [ -n "${NEW_UID:-}" ]; then
    isint "${NEW_UID}" || { log err "NEW_UID is not an integer: ${NEW_UID}"; exit 1; }
    usermod -u "${NEW_UID}" "${MY_USER}" 2>/dev/null || true
  fi

  chown -R "${MY_USER}:${MY_GROUP}" "/home/${MY_USER}" /shared 2>/dev/null || true
}

set_timezone() {
  if [ "$(id -u)" != "0" ] || [ -z "${TIMEZONE:-}" ]; then
    return 0
  fi
  if [ -f "/usr/share/zoneinfo/${TIMEZONE}" ]; then
    ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
    printf '%s\n' "${TIMEZONE}" > /etc/timezone
  else
    log warn "TIMEZONE not found: ${TIMEZONE}"
  fi
}

source_dir() {
  local dir="${1}"
  [ -d "${dir}" ] || return 0
  while IFS= read -r file; do
    [ -r "${file}" ] || continue
    log info "Sourcing ${file}"
    # shellcheck disable=SC1090
    . "${file}"
  done < <(find "${dir}" -type f -name '*.sh' | sort -u)
}

change_uid_gid
set_timezone
# Protected agentic init dir (not shadowed by cfg bind-mount over /startup.1.d).
source_dir /opt/agentic-tools/_entrypoint.d
source_dir /startup.1.d
source_dir /startup.2.d

exec "${@}"
