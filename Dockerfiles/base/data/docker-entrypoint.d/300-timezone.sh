#!/usr/bin/env bash

set -e
set -u
set -o pipefail


############################################################
# Functions
############################################################

###
### Change Timezone
###
set_timezone() {
	local env_varname="${1}"
	local debug="${2}"
	local timezone=

	if ! env_set "${env_varname}"; then
		log "info" "\$${env_varname} not set." "${debug}"
		log "info" "Setting container timezone to: UTC" "${debug}"
		run "sudo ln -sf /usr/share/zoneinfo/UTC /etc/localtime" "${debug}"
		run "echo 'UTC' | sudo tee /etc/timezone >/dev/null" "${debug}"
	else
		timezone="$( env_get "${env_varname}" )"
		if [ -f "/usr/share/zoneinfo/${timezone}" ]; then
			log "info" "Setting container timezone to: ${timezone}" "${debug}"
			run "sudo ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime" "${debug}"
			run "echo '${timezone}' | sudo tee /etc/timezone >/dev/null" "${debug}"
		else
			log "err" "Invalid timezone for \$${env_varname}." "${debug}"
			log "err" "Timezone '${timezone}' does not exist." "${debug}"
			exit 1
		fi
	fi
	run "sudo dpkg-reconfigure -f noninteractive tzdata" "${debug}"
	log "info" "Docker date set to: $(date)" "${debug}"
}
