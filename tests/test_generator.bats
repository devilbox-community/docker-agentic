#!/usr/bin/env bats

@test "gen-agentic-tools handles empty tool directory idempotently" {
  tmpdir="$(mktemp -d)"
  run env AGENTIC_TOOL_PATH="${tmpdir}" python3 bin/gen-agentic-tools.py
  [ "$status" -eq 0 ]
  [ -f .ansible/group_vars/all/work.yml ]
  grep -q '^agentic_tools: \[\]$' .ansible/group_vars/all/work.yml

  first="$(cat .ansible/group_vars/all/work.yml)"
  run env AGENTIC_TOOL_PATH="${tmpdir}" python3 bin/gen-agentic-tools.py
  [ "$status" -eq 0 ]
  second="$(cat .ansible/group_vars/all/work.yml)"
  rm -rf "${tmpdir}"
  [ "$first" = "$second" ]

  run ./bin/gen-dockerfiles.sh
  [ "$status" -eq 0 ]
}
