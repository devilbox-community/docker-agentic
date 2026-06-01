#!/usr/bin/env bash
set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck disable=SC1091
. "${CWD}/../.lib.sh"

ROOT="$(repo_root)"
cd "${ROOT}"

print_h_main "Dockerfile-base + entrypoint protect toggle scripts"

print_h_sub "Dockerfile-base COPYs toggle + oauth-helper into protected /opt/agentic-tools/_entrypoint.d/"
for df in Dockerfiles/base/Dockerfile-latest Dockerfiles/base/Dockerfile-stable .ansible/DOCKERFILES/Dockerfile-base.j2; do
	assert_grep 'COPY .*20-agentic-toggle\.sh /opt/agentic-tools/_entrypoint\.d/20-agentic-toggle\.sh' "${df}"
	assert_grep 'COPY .*10-oauth-helper\.sh /opt/agentic-tools/_entrypoint\.d/10-oauth-helper\.sh' "${df}"
done

print_h_sub "docker-entrypoint sources protected _entrypoint.d before /startup.1.d"
assert_grep 'source_dir /opt/agentic-tools/_entrypoint.d' bin/docker-entrypoint.sh
awk '
	/source_dir \/opt\/agentic-tools\/_entrypoint\.d/ { protected = NR }
	/source_dir \/startup\.1\.d/ { startup = NR }
	END { exit (protected && startup && protected < startup) ? 0 : 1 }
' bin/docker-entrypoint.sh \
	|| { echo "FAIL: protected dir not sourced before /startup.1.d" >&2; exit 1; }
