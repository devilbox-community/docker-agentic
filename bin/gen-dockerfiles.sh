#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

python3 bin/gen-agentic-tools.py ${1+"$@"}

if command -v ansible-playbook >/dev/null 2>&1; then
  (cd .ansible && ansible-playbook generate.yml -e ansible_python_interpreter=/usr/bin/python3)
elif docker info >/dev/null 2>&1; then
  docker run --rm \
    -e USER=ansible \
    -e MY_UID="$(id -u)" \
    -e MY_GID="$(id -g)" \
    -v "${ROOT_DIR}:/data" \
    -w /data/.ansible \
    cytopia/ansible:2.12-tools ansible-playbook generate.yml \
      -e ansible_python_interpreter=/usr/bin/python3
else
  python3 - <<'PY'
from pathlib import Path

root = Path.cwd()
base_template = root / ".ansible" / "DOCKERFILES" / "Dockerfile-base.j2"
work_template = root / ".ansible" / "DOCKERFILES" / "Dockerfile-work.j2"


def render(path: Path, release: str, comment: str) -> str:
    data = path.read_text()
    data = data.replace("{{ edit_comment_base }}", comment)
    data = data.replace("{{ edit_comment_work }}", comment)
    data = data.replace("{{ ubuntu_version }}", "24.04")
    data = data.replace("{{ go_version }}", "1.23.4")
    data = data.replace("{{ node_major }}", "22")
    data = data.replace("{{ rustup_profile }}", "minimal")
    data = data.replace("{{ docker_user }}", "devilboxcommunity")
    data = data.replace("{{ image_name }}", "agentic")
    data = data.replace("{{ release }}", release)
    lines = []
    skip = False
    for line in data.splitlines():
        stripped = line.lstrip()
        if stripped.startswith("{% import"):
            continue
        if stripped.startswith("{% set") or stripped.startswith("{%-") or stripped.startswith("{% for") or stripped.startswith("{% end") or stripped.startswith("{% if"):
            skip = True
            continue
        if stripped.startswith("{{-") or stripped.startswith("{#"):
            continue
        if skip:
            if stripped.startswith("USER devilbox"):
                skip = False
            else:
                continue
        lines.append(line)
    return "\n".join(lines).rstrip() + "\n"

for release in ("latest", "stable"):
    (root / "Dockerfiles" / "base" / f"Dockerfile-{release}").write_text(
        render(base_template, release, "# Auto-generated via fallback renderer: edit .ansible/DOCKERFILES/Dockerfile-base.j2 instead.")
    )
    (root / "Dockerfiles" / "work" / f"Dockerfile-{release}").write_text(
        render(work_template, release, "# Auto-generated via fallback renderer: edit .ansible/DOCKERFILES/Dockerfile-work.j2 instead.")
    )
PY
fi
