#!/usr/bin/env bash
#
# Test runner for docker-agentic.
#
# Mirrors docker-php-fpm/tests/test.sh: discovers numbered NN-*.sh scripts in
# per-stage directories and runs them sequentially. Two modes:
#
#   ./tests/test.sh
#       Run all static (no-docker) checks in tests/static/. Used by `make test`
#       and CI for fast repository-content validation.
#
#   ./tests/test.sh <image> <arch> <version> <flavour> <tag>
#       Run static checks + the per-flavour container integration tests in
#       tests/base/ and tests/work/. Reserved for future container tests; the
#       directories are stubbed today so the CI contract matches docker-php-fpm
#       and integration tests can be added without changing the runner.

set -e
set -u
set -o pipefail

IFS=$'\n'

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# shellcheck disable=SC1090
. "${CWD}/.lib.sh"


function run_stage_dir() {
	local stage_dir="${1}"
	shift
	local tests
	tests="$(find "${CWD}/${stage_dir}" -type f -name '[0-9]*.sh' 2>/dev/null | sort -u || true)"
	if [ -z "${tests}" ]; then
		return 0
	fi
	for t in ${tests}; do
		printf "\n\n\033[0;33m%s\033[0m\n" "################################################################################"
		printf "\033[0;33m# %s\033[0m\n"  "${stage_dir}/$(basename "${t}")"
		printf "\033[0;33m%s\033[0m\n"   "################################################################################"
		time bash "${t}" "${@:-}"
	done
}


if [ "${#}" -eq 0 ]; then
	run_stage_dir "static"
	exit 0
fi

if [ "${#}" -ne 5 ]; then
	echo "Usage: tests/test.sh                                 (run static checks)" >&2
	echo "       tests/test.sh <image> <arch> <version> <flavour> <tag>" >&2
	exit 1
fi

IMAGE="${1}"
ARCH="${2}"
VERSION="${3}"
FLAVOUR="${4}"
TAG="${5}"

run_stage_dir "static"

if [ "${FLAVOUR}" = "base" ] || [ "${FLAVOUR}" = "work" ]; then
	run_stage_dir "base" "${IMAGE}" "${ARCH}" "${VERSION}" "${FLAVOUR}" "${TAG}"
fi

if [ "${FLAVOUR}" = "work" ]; then
	run_stage_dir "work" "${IMAGE}" "${ARCH}" "${VERSION}" "${FLAVOUR}" "${TAG}"
fi
