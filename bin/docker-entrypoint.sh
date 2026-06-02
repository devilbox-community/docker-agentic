#!/bin/bash

set -e
set -u
set -o pipefail

MY_USER="${MY_USER:-devilbox}"
MY_GROUP="${MY_GROUP:-devilbox}"

# Source all entrypoint.d helper scripts (defines functions)
# shellcheck disable=SC1090
for f in /docker-entrypoint.d/*.sh; do
	[ -r "${f}" ] && . "${f}"
done

DEBUG_LEVEL="$( env_get "DEBUG_ENTRYPOINT" "0" )"

# 101: explicit UID/GID mapping
set_uid "NEW_UID" "${MY_USER}" "/home/${MY_USER}" "${DEBUG_LEVEL}"
set_gid "NEW_GID" "${MY_GROUP}" "/home/${MY_USER}" "${DEBUG_LEVEL}"

# 308 + 309: tool symlink toggles
enable_tools  "AGENTIC_TOOLS_ENABLE"  "${DEBUG_LEVEL}"
disable_tools "AGENTIC_TOOLS_DISABLE" "${DEBUG_LEVEL}"

exec "$@"
