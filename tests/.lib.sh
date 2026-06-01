#!/usr/bin/env bash
#
# Shared test library for docker-agentic.
#
# Models the docker-php-fpm test suite (tests/.lib.sh) but adds a small set of
# static assertion helpers because most agentic tests validate repository
# contents (Dockerfiles, install contracts, toggle script) rather than a
# running container. Future container integration tests can drop into
# tests/base/ or tests/work/ and use the same `run` / `run_fail` helpers.

set -e
set -u
set -o pipefail


###
### Colors
###
_C_RED="\033[0;31m"
_C_GREEN="\033[0;32m"
_C_YELLOW="\033[0;33m"
_C_PURPLE="\033[0;35m"
_C_RESET="\033[0m"


###
### Run a command; succeed if it exits 0
###
function run() {
	local cmd="${1}"
	printf "${_C_YELLOW}[%s] ${_C_RED}%s \$ ${_C_GREEN}${cmd}${_C_RESET}\n" "$(hostname)" "$(whoami)" >&2
	if sh -c "${cmd}"; then
		printf "${_C_GREEN}[%s]${_C_RESET}\n" "OK" >&2
		return 0
	fi
	printf "${_C_RED}[%s]${_C_RESET}\n" "NO" >&2
	return 1
}


###
### Run a command; succeed if it exits non-zero
###
function run_fail() {
	local cmd="${1}"
	printf "${_C_YELLOW}[%s] ${_C_RED}%s \$ ${_C_YELLOW}[NOT] ${_C_GREEN}${cmd}${_C_RESET}\n" "$(hostname)" "$(whoami)" >&2
	if ! sh -c "${cmd}"; then
		printf "${_C_GREEN}[%s]${_C_RESET}\n" "OK" >&2
		return 0
	fi
	printf "${_C_RED}[%s]${_C_RESET}\n" "NO" >&2
	return 1
}


###
### Print a top-level banner for a test file
###
function print_h_main() {
	local text="${1}"
	printf "\n${_C_PURPLE}################################################################################${_C_RESET}\n"
	printf "${_C_PURPLE}# %s${_C_RESET}\n" "${text}"
	printf "${_C_PURPLE}################################################################################${_C_RESET}\n"
}


###
### Print a sub-step banner for a single assertion group
###
function print_h_sub() {
	local text="${1}"
	printf "\n${_C_YELLOW}--- %s ---${_C_RESET}\n" "${text}"
}


###
### Resolve the repository root (parent of tests/)
###
function repo_root() {
	local script_dir
	script_dir="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
	(cd "${script_dir}/.." && pwd)
}


###
### Assertion helpers (static repo checks)
###
function assert_eq() {
	local actual="${1}"
	local expected="${2}"
	local msg="${3:-assert_eq}"
	if [ "${actual}" != "${expected}" ]; then
		printf "${_C_RED}FAIL${_C_RESET}: %s\n  expected: [%s]\n  actual:   [%s]\n" "${msg}" "${expected}" "${actual}" >&2
		return 1
	fi
}

function assert_file_exists() {
	local f="${1}"
	if [ ! -f "${f}" ]; then
		printf "${_C_RED}FAIL${_C_RESET}: file not found: %s\n" "${f}" >&2
		return 1
	fi
}

function assert_symlink() {
	local p="${1}"
	if [ ! -L "${p}" ]; then
		printf "${_C_RED}FAIL${_C_RESET}: symlink not found: %s\n" "${p}" >&2
		return 1
	fi
}

function assert_not_exists() {
	local p="${1}"
	if [ -e "${p}" ] || [ -L "${p}" ]; then
		printf "${_C_RED}FAIL${_C_RESET}: unexpected path: %s\n" "${p}" >&2
		return 1
	fi
}

function assert_grep() {
	local pattern="${1}"
	local file="${2}"
	if ! grep -Eq "${pattern}" "${file}"; then
		printf "${_C_RED}FAIL${_C_RESET}: pattern not in %s\n  pattern: %s\n" "${file}" "${pattern}" >&2
		return 1
	fi
}

function assert_contains() {
	local haystack="${1}"
	local needle="${2}"
	local msg="${3:-assert_contains}"
	case "${haystack}" in
		*"${needle}"*) return 0 ;;
	esac
	printf "${_C_RED}FAIL${_C_RESET}: %s\n  needle:   [%s]\n  haystack: [%s]\n" "${msg}" "${needle}" "${haystack}" >&2
	return 1
}
