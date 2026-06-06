#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate Ansible group_vars from agentic tools and extra tools definitions.

Scans agentic_tools/ (per-agent harness CLIs) and extra_tools/ (spec/workflow
utilities), resolves dependency trees, and writes the corresponding Ansible
group_vars files:

    agentic_tools/  →  .ansible/group_vars/all/agentic.yml   (per-agent images)
    extra_tools/    →  .ansible/group_vars/all/work.yml       (built into base)
"""
import os
import sys
from collections import OrderedDict
from typing import Any, Dict, List, Tuple

try:
    import yaml  # type: ignore[import]
except ModuleNotFoundError:  # pragma: no cover
    yaml = None


# --------------------------------------------------------------------------------------------------
# GLOBALS
# --------------------------------------------------------------------------------------------------

SCRIPT_PATH = str(os.path.dirname(os.path.realpath(__file__)))
REPOSITORY_PATH = str(os.path.dirname(SCRIPT_PATH))
AGENTIC_TOOL_PATH = str(os.path.join(REPOSITORY_PATH, "agentic_tools"))
EXTRA_TOOL_PATH = str(os.path.join(REPOSITORY_PATH, "extra_tools"))
GROUP_VARS_PATH = str(os.path.join(REPOSITORY_PATH, ".ansible", "group_vars", "all"))


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


def load_unmanaged_group_vars_raw(path: str, managed_keys: List[str]) -> str:
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
                if current and current_key not in managed_keys:
                    blocks.extend(current)
                current_key = line.split(":", 1)[0]
                current = [line]
            elif current:
                current.append(line)
        if current and current_key not in managed_keys:
            blocks.extend(current)
    return "".join(blocks)


# --------------------------------------------------------------------------------------------------
# TOOL DISCOVERY FUNCTIONS
# --------------------------------------------------------------------------------------------------


def get_tool_options(tool_path: str, tool_dirname: str) -> Dict[str, Any]:
    """Returns yaml dict options of a tool given by its directory path and name."""
    return load_yaml(os.path.join(tool_path, tool_dirname, "options.yml"))


def get_tool_install(tool_path: str, tool_dirname: str) -> Dict[str, Any]:
    """Returns yaml dict install configuration of a tool."""
    return load_yaml(os.path.join(tool_path, tool_dirname, "install.yml"))


def get_tools(tool_path: str, selected_tools: List[str], ignore_dependencies: bool) -> List[Dict[str, Any]]:
    """Returns a list of tool directory names from a given path.

    Args:
        tool_path: Absolute path to scan (e.g. agentic_tools/ or extra_tools/).
        selected_tools: If not empty, only gather specified tools (and its dependencies).
        ignore_dependencies: If true, all dependent tools will be ignored.
    """
    tools = []
    with os.scandir(tool_path) as it:
        for item in it:
            if not item.name.startswith(".") and item.is_dir():
                data = get_tool_options(tool_path, item.name)
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


def write_group_vars(
    tools: List[str],
    tool_path: str,
    group_vars_file: str,
    managed_keys: List[str],
    prefix: str,
) -> None:
    """Write a group_vars YAML file for ansible.

    Args:
        tools: Ordered list of tool directory names.
        tool_path: Path to the tool definitions directory.
        group_vars_file: Output filename (relative to GROUP_VARS_PATH).
        managed_keys: Top-level keys managed by this generator.
        prefix: Variable prefix (e.g. 'agentic_tools' or 'extra_tools').
    """
    os.makedirs(GROUP_VARS_PATH, exist_ok=True)
    group_vars = os.path.join(GROUP_VARS_PATH, group_vars_file)
    existing = load_yaml(group_vars) if yaml is not None and os.path.exists(group_vars) else {}
    unmanaged = {key: value for key, value in existing.items() if key not in managed_keys}
    unmanaged_raw = load_unmanaged_group_vars_raw(group_vars, managed_keys) if yaml is None else ""

    enabled_var = prefix + "_enabled"
    enabled_by_default_var = prefix + "_enabled_by_default"
    installed_only_var = prefix + "_installed_only"
    available_var = prefix + "_available"

    enabled_by_default = [
        tool for tool in tools
        if get_tool_options(tool_path, tool).get("default_enabled", False) is True
    ]
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
        fp.write(f"# The following specifies the order in which {prefix} are being installed.\n")
        fp.write(prefix + ":\n")
        for tool in tools:
            fp.write("  - " + tool + "\n")
        fp.write("\n")

        # Default-enabled tools
        fp.write(f"# The following specifies which {prefix} are linked by default.\n")
        if enabled_by_default:
            fp.write(enabled_by_default_var + ":\n")
            for tool in enabled_by_default:
                fp.write("  - " + tool + "\n")
        else:
            fp.write(enabled_by_default_var + ": []\n")
        fp.write("\n")

        # Installed-only tools
        if installed_only:
            fp.write(installed_only_var + ":\n")
            for tool in installed_only:
                fp.write("  - " + tool + "\n")
        else:
            fp.write(installed_only_var + ": []\n")
        fp.write("\n")

        # Build defines tools
        fp.write(f"# The following specifies how {prefix} are being installed.\n")
        fp.write(available_var + ":\n")
        for tool in tools:
            opts = get_tool_options(tool_path, tool)
            fp.write("  " + tool + ":\n")
            fp.write("    disabled: [" + ", ".join(str(x) for x in opts.get("exclude", [])) + "]\n")
            fp.write(load_yaml_raw(os.path.join(tool_path, tool, "install.yml"), 4))


# --------------------------------------------------------------------------------------------------
# MAIN FUNCTION
# --------------------------------------------------------------------------------------------------
def print_help() -> None:
    """Show help screen."""
    print("Usage:", os.path.basename(__file__), "[options] [TOOL]...")
    print("      ", os.path.basename(__file__), "-h, --help")
    print()
    print("This script generates Ansible group_vars files:")
    print("  .ansible/group_vars/all/agentic.yml  (from agentic_tools/)")
    print("  .ansible/group_vars/all/work.yml     (from extra_tools/)")
    print()
    print("Positional arguments:")
    print("    [TOOL]  Specify one or more tools to generate group_vars for.")
    print("            When no tool is specified, group_vars for all tools")
    print("            in both directories will be generated.")
    print("            Tools are matched against both agentic_tools/ and extra_tools/.")
    print("Optional arguments:")
    print("    -i      Ignore dependent tools.")
    print("    --help  Show this help.")


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

    # ----------------------------------------------------------------------
    # Agentic Tools (per-agent harness CLIs) → agentic.yml
    # ----------------------------------------------------------------------
    agentic_tools = get_tools(AGENTIC_TOOL_PATH, selected_tools, ignore_dependencies)
    agentic_tree = get_tool_dependency_tree(agentic_tools)
    agentic_names = resolve_tool_dependency_tree(agentic_tree)

    print("#", "-" * 78)
    print("# Agentic Tools (per-agent harness)")
    print("#", "-" * 78)
    print("Path:   ", AGENTIC_TOOL_PATH)
    print()
    print_tools(agentic_tools)
    print()
    print("Dependency Tree:")
    print_dependency_tree(agentic_tree)
    print()
    print("Build order:\n" + "\n".join(agentic_names))
    print()

    write_group_vars(
        agentic_names,
        AGENTIC_TOOL_PATH,
        "agentic.yml",
        ["agentic_tools", "agentic_tools_enabled", "agentic_tools_enabled_by_default",
         "agentic_tools_installed_only", "agentic_tools_available"],
        "agentic_tools",
    )

    # ----------------------------------------------------------------------
    # Extra Tools (spec/workflow utilities) → work.yml
    # ----------------------------------------------------------------------
    extra_tools = get_tools(EXTRA_TOOL_PATH, selected_tools, ignore_dependencies)
    extra_tree = get_tool_dependency_tree(extra_tools)
    extra_names = resolve_tool_dependency_tree(extra_tree)

    print("#", "-" * 78)
    print("# Extra Tools (spec/workflow, built into base)")
    print("#", "-" * 78)
    print("Path:   ", EXTRA_TOOL_PATH)
    print()
    print_tools(extra_tools)
    print()
    print("Dependency Tree:")
    print_dependency_tree(extra_tree)
    print()
    print("Build order:\n" + "\n".join(extra_names))
    print()

    write_group_vars(
        extra_names,
        EXTRA_TOOL_PATH,
        "work.yml",
        ["extra_tools", "extra_tools_enabled", "extra_tools_enabled_by_default",
         "extra_tools_installed_only", "extra_tools_available"],
        "extra_tools",
    )


if __name__ == "__main__":
    main(sys.argv[1:])
