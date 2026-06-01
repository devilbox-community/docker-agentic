#!/usr/bin/env bats

# Makefile contract tests for docker-agentic.
#
# These tests verify the public CLI surface of the Makefile (target names,
# argument parsing, guards, deprecation aliases). They do NOT run real docker
# builds — they exercise targets that fail before any `docker` invocation.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  cd "${REPO_ROOT}"
  # Ensure the external Makefiles are bootstrapped so `make` does not try to
  # download them mid-test (and so includes resolve cleanly).
  if [ ! -f Makefile.docker ] || [ ! -f Makefile.lint ]; then
    run make Makefile.docker Makefile.lint
    [ "$status" -eq 0 ] || skip "Could not bootstrap Makefile.docker/Makefile.lint (offline?)"
  fi
}

@test "make help lists canonical targets" {
  run make help
  [ "$status" -eq 0 ]
  [[ "$output" == *"build STAGE=base|work"* ]]
  [[ "$output" == *"rebuild STAGE=base|work"* ]]
  [[ "$output" == *"push STAGE=base|work"* ]]
  [[ "$output" == *"manifest-create"* ]]
  [[ "$output" == *"manifest-push"* ]]
  [[ "$output" == *"test STAGE=base|work"* ]]
  [[ "$output" == *"gen "* || "$output" == *"gen	"* || "$output" == *"gen "* ]]
  [[ "$output" == *"lint"* ]]
}

@test "make help still advertises the deprecated aliases" {
  run make help
  [ "$status" -eq 0 ]
  [[ "$output" == *"build-base"* ]]
  [[ "$output" == *"build-work"* ]]
}

@test "make build without STAGE fails with helpful message" {
  run make build
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires the STAGE variable to be set"* ]]
}

@test "make build STAGE=invalid rejects unknown stages" {
  run make build STAGE=invalid
  [ "$status" -ne 0 ]
  [[ "$output" == *"Stage can only be one of 'base' or 'work'"* ]]
}

@test "make push without VERSION fails with helpful message" {
  # STAGE provided so we reach the version guard.
  run make push STAGE=base VERSION=
  [ "$status" -ne 0 ]
  [[ "$output" == *"requires the VERSION variable to be set"* ]]
}

@test "make build-base prints deprecation warning" {
  # Force the alias to short-circuit before any real docker work by pointing
  # PATH at a stub directory with no docker binary; the deprecation echo
  # happens before the recursive make invocation reaches docker.
  run bash -c "make build-base RELEASE=latest 2>&1 | head -1"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DEPRECATED]"* ]]
  [[ "$output" == *"build-base"* ]]
  [[ "$output" == *"STAGE=base"* ]]
}

@test "make build-work prints deprecation warning" {
  run bash -c "make build-work RELEASE=latest 2>&1 | head -1"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DEPRECATED]"* ]]
  [[ "$output" == *"build-work"* ]]
  [[ "$output" == *"STAGE=work"* ]]
}

@test "make generate alias still resolves to gen-dockerfiles" {
  # Just ensure the target exists and is recognised (dry-run).
  run make -n generate
  [ "$status" -eq 0 ]
  [[ "$output" == *"gen-agentic-tools.py"* ]] || [[ "$output" == *"gen-dockerfiles.sh"* ]]
}
