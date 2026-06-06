[Agentic Tools: Overview](../../agentic_tools/README.md) |
Agentic Tools: `options.yml` |
[Agentic Tools: `install.yml`](AGENTIC-TOOL-install.yml.md)

---

<h2> Contributor Documentation: Agentic Tools</h2>



# Tool definition: `options.yml`

These options are for the tool generator to decide whether to build the tool and
whether it should be enabled by default in its per-agent Dockerfile.


### `name`

* Required: Yes
* Type: `str`

The display name of the tool. Must match the directory name.


### `default_enabled`

* Required: No
* Type: `bool`
* Default: `false`

If `true`, the binary is symlinked to `/usr/local/bin`.


### `exclude`

* Required: Yes
* Type: `list[str]`
* Empty: `[]`

Agentic images have no per-language version axis; keep empty.


### `depends`

* Required: Yes
* Type: `list[str]`
* Empty: `[]`

Other agentic tools that must be installed first.
