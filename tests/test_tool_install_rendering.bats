#!/usr/bin/env bats

@test "make gen renders agentic tool install lines" {
  run make gen

  [ "$status" -eq 0 ]
  [ -f Dockerfiles/work/Dockerfile-latest ]
  grep -q 'claude-code' Dockerfiles/work/Dockerfile-latest
}
