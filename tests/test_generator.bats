#!/usr/bin/env bats

@test "gen-agentic-tools handles empty tool directory idempotently" {
  run python3 bin/gen-agentic-tools.py
  [ "$status" -eq 0 ]
  [ -f .ansible/group_vars/all/work.yml ]
  grep -q '^agentic_tools: \[\]$' .ansible/group_vars/all/work.yml

  first="$(cat .ansible/group_vars/all/work.yml)"
  run python3 bin/gen-agentic-tools.py
  [ "$status" -eq 0 ]
  second="$(cat .ansible/group_vars/all/work.yml)"
  [ "$first" = "$second" ]
}
