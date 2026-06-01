#!/usr/bin/env bash
set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck disable=SC1091
. "${CWD}/../.lib.sh"

ROOT="$(repo_root)"
cd "${ROOT}"

print_h_main "Dockerfile generator output"

print_h_sub "make gen succeeds"
run "make gen >/dev/null"

print_h_sub "work Dockerfile-latest is regenerated and FROMs the base image"
assert_file_exists Dockerfiles/work/Dockerfile-latest
assert_grep '^FROM devilboxcommunity/agentic:latest-base AS work' Dockerfiles/work/Dockerfile-latest
assert_grep '^USER devilbox' Dockerfiles/work/Dockerfile-latest
assert_grep 'ENTRYPOINT \[' Dockerfiles/work/Dockerfile-latest

print_h_sub "work Dockerfile-stable FROMs the stable base image"
assert_file_exists Dockerfiles/work/Dockerfile-stable
assert_grep '^FROM devilboxcommunity/agentic:stable-base AS work' Dockerfiles/work/Dockerfile-stable

print_h_sub "rendered work Dockerfile contains an agentic tool install line"
assert_grep 'claude-code' Dockerfiles/work/Dockerfile-latest

print_h_sub "base Dockerfiles FROM the upstream ubuntu image"
assert_grep '^FROM ubuntu:24.04' Dockerfiles/base/Dockerfile-latest
assert_grep '^FROM ubuntu:24.04' Dockerfiles/base/Dockerfile-stable
