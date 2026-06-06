#!/usr/bin/env bash

set -e
set -u
set -o pipefail

IFS=$'\n'

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

###
### Source libs
###
# shellcheck disable=SC1091
. "${CWD}/.lib.sh"


###
### Sanity check
###
if [ "${#}" -ne 5 ]; then
	echo "Usage: tests/test.sh <image> <arch> <version> <flavour> <tag>" >&2
	exit 1
fi

IMAGE="${1}"
ARCH="${2}"
VERSION="${3}"
FLAVOUR="${4}"
TAG="${5}"


###
### Run tests
###
PASS_COUNT=0
FAIL_COUNT=0

function run_test_file() {
	local t="${1}"

	printf "\n\n\033[0;33m%s\033[0m\n" "################################################################################"
	printf "\033[0;33m%s %s\033[0m\n"  "#" "[${VERSION}-${FLAVOUR}] (${ARCH})"
	printf "\033[0;33m%s %s\033[0m\n"  "#" "${t} ${IMAGE} ${ARCH} ${VERSION} ${FLAVOUR} ${TAG}"
	printf "\033[0;33m%s\033[0m\n\n"   "################################################################################"

	if time "${t}" "${IMAGE}" "${ARCH}" "${VERSION}" "${FLAVOUR}" "${TAG}"; then
		PASS_COUNT="$((PASS_COUNT + 1))"
	else
		FAIL_COUNT="$((FAIL_COUNT + 1))"
	fi
}

function run_stage_dir() {
	local stage_dir="${1}"
	local tests

	tests="$(find "${CWD}/${stage_dir}" -regex "${CWD}/${stage_dir}/[0-9].+.*\.sh" | sort -u)"
	for t in ${tests}; do
		run_test_file "${t}"
	done
}

# Per-agent tool test — run base tests against the agent image.
# The base image is the parent of all agent images, so base tests
# (like UID/GID mapping, timezone, git, gh) still apply.
if [ "${FLAVOUR}" != "base" ] && [ "${FLAVOUR}" != "work" ]; then
	log "Running base-stage tests against per-agent image: ${FLAVOUR}"
	run_stage_dir "base"
else
	run_stage_dir "${FLAVOUR}"
fi

log "Test summary: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
if [ "${FAIL_COUNT}" -ne 0 ]; then
	exit 1
fi
