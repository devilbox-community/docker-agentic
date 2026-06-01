#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate Ansible group_vars from agentic tool definitions."""
import os
import sys
from collections import OrderedDict
from typing import Any, Dict, List

try:
    import yaml
except ModuleNotFoundError:  # pragma: no cover - empty Wave 1 does not require YAML parsing
    yaml = None

SCRIPT_PATH = str(os.path.dirname(os.path.realpath(__file__)))
REPOSITORY_PATH = str(os.path.dirname(SCRIPT_PATH))
AGENTIC_TOOL_PATH = os.environ.get("AGENTIC_TOOL_PATH", str(os.path.join(REPOSITORY_PATH, "agentic_tools")))
GROUP_VARS_PATH = str(os.path.join(REPOSITORY_PATH, ".ansible", "group_vars", "all"))


def get_el_by_name(items: List[Dict[str, Any]], name: str) -> Dict[str, Any]:
    """Return an element from a dict list by its name key."""
    for item in items:
        if item["name"] == name:
            return item
    print("error, key name not found by value", name, "in list:", items)
    sys.exit(1)


def load_yaml(path: str) -> Dict[str, Any]:
    """Load YAML file and return its dict."""
    if yaml is None:
        data: Dict[str, Any] = {}
        current_list = None
        with open(path, "r", encoding="utf8") as fp:
            for raw_line in fp:
                line = raw_line.strip()
                if not line or line == "---" or line.startswith("#"):
                    continue
                if line.startswith("-") and current_list:
                    data[current_list].append(line[1:].strip())
                    continue
                current_list = None
                if ":" not in line:
                    continue
                key, value = line.split(":", 1)
                key = key.strip()
                value = value.strip()
                if value in ("", "[]"):
                    data[key] = [] if value == "[]" else ""
                    if value == "":
                        current_list = key
                elif value.startswith("[") and value.endswith("]"):
                    data[key] = [item.strip().strip('"\'') for item in value[1:-1].split(",") if item.strip()]
                else:
                    data[key] = value.strip('"\'')
        return data
    with open(path, "r", encoding="utf8") as fp:
        data = yaml.safe_load(fp)
        return data or {}


def load_yaml_raw(path: str, indent: int = 0) -> str:
    """Load and return YAML file as indented string without document markers/comments."""
    lines = []
    with open(path, "r", encoding="utf8") as fp:
        for line in fp:
            if line in ("---\n", "---\r\n", "\n", "\r\n"):
                continue
            if line.startswith("#"):
                continue
            if line.strip() in ("pre:", "post:", "version:"):
                lines.append(" " * indent + line.rstrip() + " ''\n")
                continue
            lines.append(" " * indent + line)
    return "".join(lines)


def get_tool_options(tool_dirname: str) -> Dict[str, Any]:
    """Return options for an agentic tool directory."""
    return load_yaml(os.path.join(AGENTIC_TOOL_PATH, tool_dirname, "options.yml"))


def get_tools(selected_tools: List[str], ignore_dependencies: bool) -> List[Dict[str, Any]]:
    """Return agentic tool directory metadata with dependencies resolved."""
    tools = []
    if not os.path.isdir(AGENTIC_TOOL_PATH):
        os.makedirs(AGENTIC_TOOL_PATH, exist_ok=True)
    with os.scandir(AGENTIC_TOOL_PATH) as it:
        for item in it:
            if not item.name.startswith(".") and item.is_dir():
                data = get_tool_options(item.name)
                tools.append(
                    {
                        "dir": item.name,
                        "name": data["name"],
                        "deps": data.get("depends", []),
                        "exclude": data.get("exclude", []),
                    }
                )

    items = []
    for tool in tools:
        if tool["deps"] and not ignore_dependencies:
            deps = []
            for dep in tool["deps"]:
                deps.append(get_el_by_name(tools, dep))
            tool["deps"] = deps
        else:
            tool["deps"] = []
        items.append(tool)

    if selected_tools:
        return [get_el_by_name(items, tool_name) for tool_name in selected_tools]
    return sorted(items, key=lambda item: item["dir"])


def get_tool_dependency_tree(tools: List[Dict[str, Any]]) -> OrderedDict[str, Any]:
    """Return dictionary of tool dependency tree."""
    tool_tree = OrderedDict()  # type: OrderedDict[str, Any]
    for tool in tools:
        tool_tree[tool["dir"]] = {}
        if len(tool["deps"]) > 0:
            tool_tree[tool["dir"]] = get_tool_dependency_tree(tool["deps"])
    return tool_tree


def resolve_tool_dependency_tree(tree: OrderedDict[str, Any]) -> List[str]:
    """Return sorted list of resolved dependencies."""
    resolved = []
    for key, _ in tree.items():
        if tree[key]:
            childs = resolve_tool_dependency_tree(tree[key])
            for child in childs:
                if child not in resolved:
                    resolved.append(child)
        if key not in resolved:
            resolved.append(key)
    return resolved


def write_group_vars(tools: List[str]) -> None:
    """Write work.yml group_vars for Ansible."""
    os.makedirs(GROUP_VARS_PATH, exist_ok=True)
    group_vars = os.path.join(GROUP_VARS_PATH, "work.yml")

    with open(group_vars, "w", encoding="utf8") as fp:
        fp.write("---\n\n")
        fp.write("# DO NOT ALTER THIS FILE - IT IS AUTOGENERATED.\n\n")

        if not tools:
            fp.write("agentic_tools: []\n")
            fp.write("agentic_tools_enabled: []\n")
            fp.write("agentic_tools_available: {}\n")
            return

        fp.write("agentic_tools:\n")
        for tool in tools:
            fp.write("  - " + tool + "\n")
        fp.write("agentic_tools_enabled:\n")
        for tool in tools:
            fp.write("  - " + tool + "\n")
        fp.write("agentic_tools_available:\n")
        for tool in tools:
            opts = get_tool_options(tool)
            fp.write("  " + tool + ":\n")
            fp.write("    disabled: [" + ", ".join(str(x) for x in opts.get("exclude", [])) + "]\n")
            fp.write(load_yaml_raw(os.path.join(AGENTIC_TOOL_PATH, tool, "install.yml"), 4))


def print_help() -> None:
    """Show help screen."""
    print("Usage:", os.path.basename(__file__), "[options] [AGENTIC-TOOL]...")
    print("      ", os.path.basename(__file__), "-h, --help")
    print()
    print("Generate .ansible/group_vars/all/work.yml from agentic_tools/.")
    print("Optional arguments:")
    print("    -i          Ignore dependent tools.")


def main(argv: List[str]) -> None:
    """Main entrypoint."""
    ignore_dependencies = False
    selected_tools = []
    if len(argv):
        for arg in argv:
            if arg in ("-h", "--help"):
                print_help()
                sys.exit(0)
        for arg in argv:
            if arg.startswith("-") and arg != "-i":
                print("Invalid argument:", arg)
                print("Use -h or --help for help")
                sys.exit(1)
            if arg == "-i":
                ignore_dependencies = True
            else:
                selected_tools.append(arg)

    tools = get_tools(selected_tools, ignore_dependencies)
    tool_tree = get_tool_dependency_tree(tools)
    names = resolve_tool_dependency_tree(tool_tree)

    print("Repository:    ", REPOSITORY_PATH)
    print("Agentic Tools: ", AGENTIC_TOOL_PATH)
    print("Group Vars:    ", GROUP_VARS_PATH)
    print("Tools:         ", ", ".join(names) if names else "<none>")

    write_group_vars(names)


if __name__ == "__main__":
    main(sys.argv[1:])
