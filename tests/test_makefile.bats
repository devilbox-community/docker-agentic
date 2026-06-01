#!/usr/bin/env bats

@test "make help lists required targets" {
  run make help
  [ "$status" -eq 0 ]
  [[ "$output" == *"gen"* ]]
  [[ "$output" == *"generate"* ]]
  [[ "$output" == *"build-work"* ]]
  [[ "$output" == *"test"* ]]
  [[ "$output" == *"lint"* ]]
}

@test "make lint runs yamllint clean" {
  run make lint
  [ "$status" -eq 0 ]
}
