#!/usr/bin/env bash

set -e
set -u
set -o pipefail

_RED="\033[0;31m"
_GREEN="\033[0;32m"
_YELLOW="\033[0;33m"
_RESET="\033[0m"

###
### Log
###
function log() {
	printf "${_YELLOW}%s${_RESET}\n" "${1}"
}


###
### Pass
###
function pass() {
	printf "${_GREEN}PASS${_RESET}: %s\n" "${1}"
}


###
### Fail
###
function fail() {
	printf "${_RED}FAIL${_RESET}: %s\n" "${1}" >&2
	exit 1
}


###
### Run
###
function run() {
	local cmd="${1}"

	printf "${_YELLOW}[%s] ${_RED}%s \$ ${_GREEN}%s${_RESET}\n" "$(hostname)" "$(whoami)" "${cmd}" >&2
	if sh -c "${cmd}"; then
		printf "${_GREEN}[%s]${_RESET}\n" "OK" >&2
		return 0
	fi
	printf "${_RED}[%s]${_RESET}\n" "NO" >&2
	fail "Command failed: ${cmd}"
}


###
### Run (must fail in order to succeed)
###
function run_fail() {
	local cmd="${1}"

	printf "${_YELLOW}[%s] ${_RED}%s \$ ${_YELLOW}[NOT] ${_GREEN}%s${_RESET}\n" "$(hostname)" "$(whoami)" "${cmd}" >&2
	if ! sh -c "${cmd}"; then
		printf "${_GREEN}[%s]${_RESET}\n" "OK" >&2
		return 0
	fi
	printf "${_RED}[%s]${_RESET}\n" "NO" >&2
	fail "Command unexpectedly succeeded: ${cmd}"
}


###
### Docker run
###
function run_in_container() {
	local cmd="${1}"
	run "timeout 60 docker run --rm \"${IMAGE}\" sh -c \"${cmd}\""
}
