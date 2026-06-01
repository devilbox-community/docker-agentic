#!/usr/bin/env bats

@test "make gen renders latest work Dockerfile with base image contract" {
  run make gen
  [ "$status" -eq 0 ]
  [ -f Dockerfiles/work/Dockerfile-latest ]
  grep -q 'FROM ubuntu:24.04' Dockerfiles/work/Dockerfile-latest
  grep -q 'USER devilbox' Dockerfiles/work/Dockerfile-latest
  grep -q 'ENTRYPOINT \["/usr/bin/tini"' Dockerfiles/work/Dockerfile-latest
}
