#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate Ansible group_vars from agentic tools (installed software) definition."""
import os
import sys
from collections import OrderedDict
from typing import Any, Dict, List

try:
    import yaml  # type: ignore[import]
except ModuleNotFoundError:  # pragma: no cover - host bootstrap may not have PyYAML
    yaml = None


# --------------------------------------------------------------------------------------------------
# GLOBALS
# --------------------------------------------------------------------------------------------------

SCRIPT_PATH = str(os.path.dirname(os.path.realpath(__file__)))
REPOSITORY_PATH = str(os.path.dirname(SCRIPT_PATH))
AGENTIC_TOOL_PATH = os.environ.get("AGENTIC_TOOL_PATH", str(os.path.join(REPOSITORY_PATH, "agentic_tools")))
GROUP_VARS_PATH = str(os.path.join(REPOSITORY_PATH, ".ansible", "group_vars", "all"))

MANAGED_GROUP_VARS = [
    "agentic_tools",
    "agentic_tools_enabled",
    "agentic_tools_enabled_by_default",
    "agentic_tools_installed_only",
    "agentic_tools_available",
]


# --------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# --------------------------------------------------------------------------------------------------


def get_el_by_name(items: List[Dict[str, Any]], name: str) -> Dict[str, Any]:
    """Returns an element from a dict list by its 'name' key with given value."""
    for item in items:
        if item["name"] == name:
            return item
    print("warn, key name not found by value", name, "in list: ", items)
    return {}


def load_yaml(path: str) -> Dict[str, Any]:
    """Load yaml file and return its dict()."""
    if yaml is None:
        data: Dict[str, Any] = {}
        current_list = None
        with open(path, "r", encoding="utf8") as fp:
            for raw_line in fp:
                line = raw_line.strip()
                if not line or line == "---" or line.startswith("#"):
                    continue
                if line.startswith("-") and current_list:
                    data[current_list].append(line[1:].strip().strip('"\''))
                    continue
                current_list = None
                if ":" not in line:
                    continue
                key, value = line.split(":", 1)
                key = key.strip()
                value = value.strip()
                if not value:
                    data[key] = []
                    current_list = key
                elif value == "[]":
                    data[key] = []
                elif value.startswith("[") and value.endswith("]"):
                    data[key] = [item.strip().strip('"\'') for item in value[1:-1].split(",") if item.strip()]
                elif value.lower() == "true":
                    data[key] = True
                elif value.lower() == "false":
                    data[key] = False
                else:
                    data[key] = value.strip('"\'')
        return data
    with open(path, "r", encoding="utf8") as fp:
        data = yaml.safe_load(fp)
        return data or {}


def dump_yaml(path: str, data: Dict[str, Any]) -> None:
    """Dump dict() to yaml file."""
    if yaml is None:
        with open(path, "w", encoding="utf8") as fp:
            fp.write("---\n")
            for key, value in data.items():
                if isinstance(value, list):
                    fp.write(key + ":\n")
                    for item in value:
                        fp.write("  - " + str(item) + "\n")
                else:
                    fp.write(key + ": " + str(value) + "\n")
        return
    with open(path, "w", encoding="utf8") as fp:
        yaml.safe_dump(data, fp, default_flow_style=False, sort_keys=False)


def load_yaml_raw(path: str, indent: int = 0) -> str:
    """Load and returns yaml file as str."""
    lines = []
    with open(path, "r", encoding="utf8") as fp:
        for line in fp:
            # Remove: empty lines and ---
            if line in ("---\n", "---\r\n", "\n", "\r\n"):
                continue
            # Remove: comments
            if line.startswith("#"):
                continue
            if line.strip() in ("pre:", "post:", "version:"):
                lines.append(" " * indent + line.rstrip() + " ''\n")
                continue
            lines.append(" " * indent + line)
    return "".join(lines)


def load_unmanaged_group_vars_raw(path: str) -> str:
    """Load and returns unmanaged top-level yaml blocks as str."""
    if not os.path.exists(path):
        return ""

    blocks = []
    current = []
    current_key = ""
    with open(path, "r", encoding="utf8") as fp:
        for line in fp:
            if line.startswith("---") or line.startswith("#") or not line.strip():
                continue
            if not line.startswith(" ") and ":" in line:
                if current and current_key not in MANAGED_GROUP_VARS:
                    blocks.extend(current)
                current_key = line.split(":", 1)[0]
                current = [line]
            elif current:
                current.append(line)
        if current and current_key not in MANAGED_GROUP_VARS:
            blocks.extend(current)
    return "".join(blocks)


# --------------------------------------------------------------------------------------------------
# TOOL FUNCTIONS
# --------------------------------------------------------------------------------------------------


def get_tool_options(tool_dirname: str) -> Dict[str, Any]:
    """Returns yaml dict options of an agentic tool given by its absolute file path."""
    return load_yaml(os.path.join(AGENTIC_TOOL_PATH, tool_dirname, "options.yml"))


def get_tool_install(tool_dirname: str) -> Dict[str, Any]:
    """Returns yaml dict install configuration of an agentic tool given by its absolute file path."""
    return load_yaml(os.path.join(AGENTIC_TOOL_PATH, tool_dirname, "install.yml"))


def get_tools(selected_tools: List[str], ignore_dependencies: bool) -> List[Dict[str, Any]]:
    """Returns a list of agentic tool directory names.

    Args:
        selected_tools: If not empty, only gather specified tools (and its dependencies).
        ignore_dependencies: If true, all dependent tools will be ignored.
    """
    tools = []
    with os.scandir(AGENTIC_TOOL_PATH) as it:
        for item in it:
            if not item.name.startswith(".") and item.is_dir():
                data = get_tool_options(item.name)
                tools.append(
                    {
                        "dir": item.name,
                        "name": data["name"],
                        "default_enabled": data.get("default_enabled", False),
                        "deps": data.get("depends", []),
                        "exclude": data.get("exclude", []),
                    }
                )
    # Convert list of deps into dict(dir, name, deps)
    items = []
    for tool in tools:
        if tool["deps"] and not ignore_dependencies:
            deps = []
            for dep in tool["deps"]:
                dep_tool = get_el_by_name(tools, dep)
                if dep_tool:
                    deps.append(dep_tool)
            tool["deps"] = deps
            items.append(tool)
        else:
            tool["deps"] = []
            items.append(tool)
    # Check if we only want to read a single tool
    if selected_tools:
        selected = []
        for tool_name in selected_tools:
            tool = get_el_by_name(items, tool_name)
            if not tool:
                print("Invalid tool:", tool_name)
                sys.exit(1)
            selected.append(tool)
        return selected
    return sorted(items, key=lambda item: item["dir"])


def get_tool_dependency_tree(tools: List[Dict[str, Any]]) -> OrderedDict[str, Any]:
    """Returns dictionary of tool dependency tree."""
    tool_tree = OrderedDict()  # type: OrderedDict[str, Any]

    for tool in tools:
        tool_name = tool["dir"]
        tool_deps = tool["deps"]

        tool_tree[tool_name] = {}

        # Do we have tool requirements?
        if len(tool_deps) > 0:
            tool_tree[tool_name] = get_tool_dependency_tree(tool_deps)
    return tool_tree


def resolve_tool_dependency_tree(tree: OrderedDict[str, Any]) -> List[str]:
    """Returns sorted list of resolved dependencies."""
    resolved = []
    for key, _ in tree.items():
        # Has dependenies
        if tree[key]:
            childs = resolve_tool_dependency_tree(tree[key])
            for child in childs:
                if child not in resolved:
                    resolved.append(child)
        # Add current node, if not already available
        if key not in resolved:
            resolved.append(key)
    return resolved


# --------------------------------------------------------------------------------------------------
# PRINT FUNCTIONS
# --------------------------------------------------------------------------------------------------


def print_tools(tools: List[Dict[str, Any]]) -> None:
    """Print directory tools."""
    for tool in tools:
        print(tool["dir"] + "/")
        print("   name:", tool["name"])
        print("   deps:", end=" ")
        for dep in tool["deps"]:
            print(dep["name"], end=", ")
        print()
        print("   excl:", tool["exclude"])
        print("   default_enabled:", tool["default_enabled"])


def print_dependency_tree(tree: Dict[str, Any], lvl: int = 0) -> None:
    """Print dependency tree of tools."""
    for key, value in tree.items():
        print(" " * lvl, "-", key)
        if value:
            print_dependency_tree(tree[key], lvl + 2)


# --------------------------------------------------------------------------------------------------
# WRITE ANSIBLE GROUP_VARS FUNCTIONS
# --------------------------------------------------------------------------------------------------


def write_group_vars(tools: List[str]) -> None:
    """Write work.yml group_vars for ansible."""
    os.makedirs(GROUP_VARS_PATH, exist_ok=True)
    group_vars = os.path.join(GROUP_VARS_PATH, "work.yml")
    existing = load_yaml(group_vars) if yaml is not None and os.path.exists(group_vars) else {}
    unmanaged = {key: value for key, value in existing.items() if key not in MANAGED_GROUP_VARS}
    unmanaged_raw = load_unmanaged_group_vars_raw(group_vars) if yaml is None else ""
    enabled_by_default = [tool for tool in tools if get_tool_options(tool).get("default_enabled", False) is True]
    installed_only = [tool for tool in tools if tool not in enabled_by_default]

    with open(group_vars, "w", encoding="utf8") as fp:
        fp.write("---\n\n")
        fp.write("# GENERATED BY bin/gen-agentic-tools.py — DO NOT EDIT MANUALLY\n\n")

        if unmanaged:
            if yaml is None:
                for key, value in unmanaged.items():
                    fp.write(key + ": " + str(value) + "\n")
            else:
                fp.write(yaml.safe_dump(unmanaged, default_flow_style=False, sort_keys=False))
            fp.write("\n")
        elif unmanaged_raw:
            fp.write(unmanaged_raw)
            fp.write("\n")

        # Enabled tools
        fp.write("# The following specifies the order in which agentic tools are being installed.\n")
        fp.write("agentic_tools:\n")
        for tool in tools:
            fp.write("  - " + tool + "\n")
        fp.write("\n")

        # Default-enabled tools
        fp.write("# The following specifies which agentic tools are linked by default.\n")
        if enabled_by_default:
            fp.write("agentic_tools_enabled_by_default:\n")
            for tool in enabled_by_default:
                fp.write("  - " + tool + "\n")
        else:
            fp.write("agentic_tools_enabled_by_default: []\n")
        fp.write("\n")

        # Installed-only tools
        if installed_only:
            fp.write("agentic_tools_installed_only:\n")
            for tool in installed_only:
                fp.write("  - " + tool + "\n")
        else:
            fp.write("agentic_tools_installed_only: []\n")
        fp.write("\n")

        # Build defines tools
        fp.write("# The following specifies how agentic tools are being installed.\n")
        fp.write("agentic_tools_available:\n")
        for tool in tools:
            opts = get_tool_options(tool)
            fp.write("  " + tool + ":\n")
            fp.write("    disabled: [" + ", ".join(str(x) for x in opts.get("exclude", [])) + "]\n")
            fp.write(load_yaml_raw(os.path.join(AGENTIC_TOOL_PATH, tool, "install.yml"), 4))


# --------------------------------------------------------------------------------------------------
# MAIN FUNCTION
# --------------------------------------------------------------------------------------------------
def print_help() -> None:
    """Show help screen."""
    print("Usage:", os.path.basename(__file__), "[options] [AGENTIC-TOOL]...")
    print("      ", os.path.basename(__file__), "-h, --help")
    print()
    print("This script will generate the Ansible group_vars file: .ansible/group_vars/all/work.yml")
    print("based on all the tools found in agentic_tools/ directory.")
    print()
    print("Positional arguments:")
    print("    [AGENTIC-TOOL]  Specify None, one or more agentic tools to generate group_vars for.")
    print("                    When no agentic tool is specified (argument is omitted), group_vars")
    print("                    for all tools will be genrated.")
    print("                    When one or more agentic tool are specified, only group_vars for")
    print("                    these tools will be created.")
    print("                        only be generated for this single tool (and its dependencies).")
    print("                        This is useful if you want to test new tools and not build all")
    print("                        previous tools in the Dockerfile.")
    print()
    print("                        Note: You still need to generate the Dockerfiles via Ansible for")
    print("                              the changes to take effect, before building the image.")
    print("Optional arguments:")
    print("    -i              Ignore dependent tools.")
    print("                    By default each tool is checked for dependencies of other")
    print("                    tools.")
    print("                    By specifying -i, those dependent tools are not beeing added to")
    print("                    ansible group_vars. Use at your own risk.")


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

    # Get tools in order of dependencies
    tools = get_tools(selected_tools, ignore_dependencies)
    tool_tree = get_tool_dependency_tree(tools)
    names = resolve_tool_dependency_tree(tool_tree)

    print("#", "-" * 78)
    print("# Paths")
    print("#", "-" * 78)
    print("Repository:    ", REPOSITORY_PATH)
    print("Agentic Tools: ", AGENTIC_TOOL_PATH)
    print("Group Vars:    ", GROUP_VARS_PATH)
    print()

    print("#", "-" * 78)
    print("# Tool directories")
    print("#", "-" * 78)
    print_tools(tools)
    print()

    print("#", "-" * 78)
    print("# Build Dependency Tree")
    print("#", "-" * 78)
    print_dependency_tree(tool_tree)
    print()

    print("#", "-" * 78)
    print("# Build order")
    print("#", "-" * 78)
    print("\n".join(names))

    # Create group_vars file work.yml
    write_group_vars(names)


if __name__ == "__main__":
    main(sys.argv[1:])
