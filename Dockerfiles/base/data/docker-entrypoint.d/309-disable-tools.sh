#!/usr/bin/env bash

set -e
set -u
set -o pipefail


############################################################
# Helper Functions
############################################################

_tool_slug_normalize() {
	echo "${1}" | tr '[:upper:]' '[:lower:]' | xargs
}

_tool_binary_for_slug() {
	local slug="${1}"
	local prefix="${AGENTIC_TOOLS_PREFIX:-/opt/agentic-tools}"
	local slug_bin_dir="${prefix}/${slug}/bin"
	local entry=

	[ -d "${slug_bin_dir}" ] || return 1
	for entry in "${slug_bin_dir}"/*; do
		[ -e "${entry}" ] || continue
		if [ -f "${entry}" ] || [ -L "${entry}" ]; then
			basename "${entry}"
			return 0
		fi
	done
	return 1
}


############################################################
# Functions
############################################################

###
### Disable agentic tools
###
disable_tools() {
	local tools_varname="${1}"
	local debug="${2}"
	local bin_dir="${AGENTIC_BIN_DIR:-/usr/local/bin}"
	local tools=
	local tool=
	local binary=

	if ! env_set "${tools_varname}"; then
		log "info" "\$${tools_varname} not set. Not disabling any agentic tools." "${debug}"
	else
		tools="$( env_get "${tools_varname}" )"

		if [ -z "${tools}" ]; then
			log "info" "\$${tools_varname} set, but empty. Not disabling any agentic tools." "${debug}"
			return 0
		fi

		log "info" "Disabling the following agentic tools: ${tools}" "${debug}"

		while read -r tool; do
			tool="$( _tool_slug_normalize "${tool}" )"
			[ -n "${tool}" ] || continue

			if binary="$( _tool_binary_for_slug "${tool}" )"; then
				run "sudo rm -f ${bin_dir}/${binary}" "${debug}"
			else
				log "warn" "Disabling agentic tool: '${tool}' does not exist or has no binary" "${debug}"
			fi
		done <<< "$( echo "${tools}" | tr ',' '\n' )"
	fi
}
