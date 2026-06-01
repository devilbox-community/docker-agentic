#!/usr/bin/env bash
set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck disable=SC1091
. "${CWD}/../.lib.sh"

ROOT="$(repo_root)"
cd "${ROOT}"

print_h_main "browser oauth helper"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fifo="${tmpdir}/url"
helper="${tmpdir}/bin/dvl-open-host"
profile="${tmpdir}/profile.d/dvl-browser.sh"

print_h_sub "dvl-open-host installs and pipes URL through FIFO"
DVL_OPEN_HOST_BIN="${helper}" \
	DVL_BROWSER_PROFILE="${profile}" \
	DVL_OAUTH_DIR="${tmpdir}/oauth" \
	DVL_OAUTH_FIFO="${fifo}" \
	bash Dockerfiles/base/data/startup.1.d/10-oauth-helper.sh

DVL_OAUTH_FIFO="${fifo}" "${helper}" https://example.com &
helper_pid="$!"

IFS= read -r written <"${fifo}"
wait "${helper_pid}"

assert_eq "${written}" "https://example.com" "URL written to FIFO"

print_h_sub "startup script references production helper path"
assert_grep '/usr/local/bin/dvl-open-host' Dockerfiles/base/data/startup.1.d/10-oauth-helper.sh
