#!/usr/bin/env bats

setup() {
  shopt -s nullglob
}

@test "agentic tool directories expose required contract files" {
  tool_dirs=(agentic_tools/*/)

  [ "${#tool_dirs[@]}" -ge 15 ]

  for dir in "${tool_dirs[@]}"; do
    [ -f "${dir}options.yml" ]
    [ -f "${dir}install.yml" ]
    [ -f "${dir}README.md" ]
  done
}

@test "options.yml files define name, exclude, and depends keys" {
  for dir in agentic_tools/*/; do
    grep -Eq '^name:' "${dir}options.yml"
    grep -Eq '^exclude:' "${dir}options.yml"
    grep -Eq '^depends:' "${dir}options.yml"
  done
}

@test "install.yml files define supported all.type values" {
  for dir in agentic_tools/*/; do
    grep -Eq '^all:' "${dir}install.yml"
    grep -Eq '^[[:space:]]+type:[[:space:]]*(npm|pip|curl|custom|apt)[[:space:]]*$' "${dir}install.yml"
  done
}

@test "README files document authentication and persistence" {
  for dir in agentic_tools/*/; do
    [ -s "${dir}README.md" ]
    grep -q 'Authentication' "${dir}README.md"
    grep -q 'Persistence' "${dir}README.md"
  done
}
