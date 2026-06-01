#!/usr/bin/env bash
set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck disable=SC1091
. "${CWD}/../.lib.sh"

ROOT="$(repo_root)"
cd "${ROOT}"

print_h_main "Makefile public CLI surface"

if [ ! -f Makefile.docker ] || [ ! -f Makefile.lint ]; then
	print_h_sub "bootstrapping Makefile.docker / Makefile.lint"
	if ! make Makefile.docker Makefile.lint >/dev/null 2>&1; then
		echo "SKIP: cannot bootstrap Makefile.docker/Makefile.lint (offline?)" >&2
		exit 0
	fi
fi

print_h_sub "make help advertises canonical targets"
help_out="$(make help)"
assert_contains "${help_out}" "build STAGE=base|work" "help missing build STAGE"
assert_contains "${help_out}" "rebuild STAGE=base|work" "help missing rebuild STAGE"
assert_contains "${help_out}" "push STAGE=base|work" "help missing push STAGE"
assert_contains "${help_out}" "manifest-create" "help missing manifest-create"
assert_contains "${help_out}" "manifest-push" "help missing manifest-push"
assert_contains "${help_out}" "test STAGE=base|work" "help missing test STAGE"
assert_contains "${help_out}" "lint" "help missing lint"
case "${help_out}" in
	*"gen "*|*$'gen\t'*) ;;
	*) echo "FAIL: help missing 'gen' target" >&2; exit 1 ;;
esac

print_h_sub "make help still advertises deprecated aliases"
assert_contains "${help_out}" "build-base" "help missing build-base alias"
assert_contains "${help_out}" "build-work" "help missing build-work alias"

print_h_sub "make build without STAGE fails with helpful message"
if out="$(make build 2>&1)"; then
	echo "FAIL: make build (no STAGE) unexpectedly succeeded" >&2
	exit 1
fi
assert_contains "${out}" "requires the STAGE variable to be set" "missing STAGE guard message"

print_h_sub "make build STAGE=invalid rejects unknown stages"
if out="$(make build STAGE=invalid 2>&1)"; then
	echo "FAIL: make build STAGE=invalid unexpectedly succeeded" >&2
	exit 1
fi
assert_contains "${out}" "Stage can only be one of 'base' or 'work'" "missing stage validation message"

print_h_sub "make push without VERSION fails with helpful message"
if out="$(make push STAGE=base VERSION= 2>&1)"; then
	echo "FAIL: make push (no VERSION) unexpectedly succeeded" >&2
	exit 1
fi
assert_contains "${out}" "requires the VERSION variable to be set" "missing VERSION guard message"

print_h_sub "make build-base prints deprecation warning"
build_base_out="$(make build-base RELEASE=latest 2>&1 || true)"
first_line="$(printf '%s\n' "${build_base_out}" | head -1)"
assert_contains "${first_line}" "[DEPRECATED]" "build-base missing [DEPRECATED]"
assert_contains "${first_line}" "build-base" "build-base missing alias name"
assert_contains "${first_line}" "STAGE=base" "build-base missing canonical hint"

print_h_sub "make build-work prints deprecation warning"
build_work_out="$(make build-work RELEASE=latest 2>&1 || true)"
first_line="$(printf '%s\n' "${build_work_out}" | head -1)"
assert_contains "${first_line}" "[DEPRECATED]" "build-work missing [DEPRECATED]"
assert_contains "${first_line}" "build-work" "build-work missing alias name"
assert_contains "${first_line}" "STAGE=work" "build-work missing canonical hint"

print_h_sub "make generate alias dispatches to gen-dockerfiles"
gen_out="$(make -n generate)"
case "${gen_out}" in
	*"gen-agentic-tools.py"*|*"gen-dockerfiles.sh"*) ;;
	*) echo "FAIL: 'make -n generate' did not reference gen scripts" >&2; exit 1 ;;
esac
