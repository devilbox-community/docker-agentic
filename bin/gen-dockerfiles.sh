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
import re

root = Path.cwd()
base_template = root / ".ansible" / "DOCKERFILES" / "Dockerfile-base.j2"
work_template = root / ".ansible" / "DOCKERFILES" / "Dockerfile-work.j2"


def scalar(value):
    if value is None:
        return ""
    if str(value).strip() == "None":
        return ""
    return str(value).strip().strip('"\'')


def parse_simple_yaml(path: Path) -> dict:
    data = {}
    current = data
    stack = [(0, data)]
    lines = path.read_text().splitlines()
    index = 0
    while index < len(lines):
        raw = lines[index]
        index += 1
        stripped = raw.strip()
        if not stripped or stripped == "---" or stripped.startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        while stack and indent < stack[-1][0]:
            stack.pop()
        current = stack[-1][1]
        if ":" not in stripped:
            continue
        key, value = stripped.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value == "|":
            block = []
            while index < len(lines):
                next_raw = lines[index]
                next_indent = len(next_raw) - len(next_raw.lstrip(" "))
                if next_raw.strip() and next_indent <= indent:
                    break
                block.append(next_raw[indent + 2:] if len(next_raw) >= indent + 2 else "")
                index += 1
            current[key] = "\n".join(block).strip()
        elif value == "":
            child = {}
            current[key] = child
            stack.append((indent + 2, child))
        elif value == "[]":
            current[key] = []
        elif value.startswith("[") and value.endswith("]"):
            current[key] = [item.strip().strip('"\'') for item in value[1:-1].split(",") if item.strip()]
        else:
            current[key] = scalar(value)
    return data


def continuation(command: str) -> str:
    return " \\\n+    && ".join(line for line in command.splitlines() if line.strip())


def render_tool_installs() -> str:
    chunks = []
    for tool_dir in sorted((root / "agentic_tools").iterdir()):
        if not tool_dir.is_dir():
            continue
        install = parse_simple_yaml(tool_dir / "install.yml")
        all_install = install.get("all", {})
        tool_type = all_install.get("type", "")
        package = scalar(all_install.get("package"))
        version = scalar(all_install.get("version"))
        pre = scalar(all_install.get("pre"))
        post = scalar(all_install.get("post"))
        command = scalar(all_install.get("command"))

        commands = []
        if pre:
            commands.append(pre)
        if tool_type == "npm":
            commands.append(f"npm install -g {package}{('@' + version) if version else ''}")
        elif tool_type == "pip":
            commands.append(f"pipx install {package}{('==' + version) if version else ''}")
        elif tool_type == "curl":
            commands.append(command or package)
        elif tool_type == "custom":
            commands.append(command or post)
            post = "" if not command else post
        elif tool_type == "apt":
            commands.append(f"apt-get update && apt-get install -y --no-install-recommends {package} && rm -rf /var/lib/apt/lists/*")
        if post:
            commands.append(post)
        if not commands:
            continue
        body = continuation("\n".join(commands))
        chunks.append(f"# -------------------- {tool_dir.name} --------------------\nRUN set -eux \\\n+    && {body} \\\n+    && true")
    return "\n\n".join(chunks)


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
    tool_block_inserted = False
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
                if path == work_template and not tool_block_inserted:
                    lines.append(render_tool_installs())
                    tool_block_inserted = True
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
