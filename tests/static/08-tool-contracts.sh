#!/usr/bin/env bash
set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck disable=SC1091
. "${CWD}/../.lib.sh"

ROOT="$(repo_root)"
cd "${ROOT}"

print_h_main "agentic tool contracts (options.yml / install.yml / README.md)"

shopt -s nullglob
tool_dirs=(agentic_tools/*/)
shopt -u nullglob

print_h_sub "at least 15 tool directories exist"
[ "${#tool_dirs[@]}" -ge 15 ] || { echo "FAIL: only ${#tool_dirs[@]} tool dirs found" >&2; exit 1; }

for dir in "${tool_dirs[@]}"; do
	tool="$(basename "${dir}")"
	if [ "${tool}" = "_defaults.yml" ] || [ "${tool}" = "_defaults" ]; then
		continue
	fi
	print_h_sub "${tool}: contract files present"
	assert_file_exists "${dir}options.yml"
	assert_file_exists "${dir}install.yml"
	assert_file_exists "${dir}README.md"

	assert_grep '^name:' "${dir}options.yml"
	assert_grep '^exclude:' "${dir}options.yml"
	assert_grep '^depends:' "${dir}options.yml"

	assert_grep '^all:' "${dir}install.yml"
	assert_grep '^[[:space:]]+type:[[:space:]]*(npm|pip|curl|custom|apt)[[:space:]]*$' "${dir}install.yml"

	[ -s "${dir}README.md" ] || { echo "FAIL: empty README: ${dir}" >&2; exit 1; }
	assert_grep 'Authentication' "${dir}README.md"
	assert_grep 'Persistence' "${dir}README.md"
done
