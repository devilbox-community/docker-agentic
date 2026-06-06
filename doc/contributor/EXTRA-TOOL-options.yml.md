[Agent Tools: Overview](../../agentic_tools/README.md) |
Agent Tools: `options.yml` |
[Agent Tools: `install.yml`](AGENT-TOOL-install.yml.md)

---

<h2><img name="Documentation" title="Documentation" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> Contributor Documentation: Agent Tools</h2>



# Tool definition: `options.yml`

These options are purely for the tool generator to decide whether or not to build
the tool, in what order to build it (order of dependencies) and whether it
should be enabled by default (symlinked to `/usr/local/bin`).

Agent tools differ from agentic tools: agent tools are **AI coding agent harness
CLIs** that each get their own Docker image. Agentic tools are shared spec/
workflow tools built into the base image.


### `name`

* Required: Yes
* Type: `str`

The display name of the tool. Must match the directory name for the generator
to resolve dependencies correctly.

Example:
```yaml
name: claude-code
```


### `default_enabled`

* Required: No
* Type: `bool`
* Default: `false`

If `true`, the tool binary will be symlinked into `/usr/local/bin` at build
time in the per-agent Dockerfile.

Example:
```yaml
default_enabled: true
```


### `exclude`

* Required: Yes
* Type: `list[str]`
* Empty: `[]`

Agentic images have no per-language version axis; this field should be left
empty. Kept for structural compatibility with the `docker-php-fpm` tool
definition format.

Example:
```yaml
exclude: []
```


### `depends`

* Required: Yes
* Type: `list[str]`
* Empty: `[]`

List of other agent tool names (directory names) that must be built/installed
before this tool. The generator resolves the dependency tree and orders tools
accordingly. Note: agent tools can depend on agentic tools (which are in the
base image) without listing them here.

Example:
```yaml
depends: [claude-code]
```
