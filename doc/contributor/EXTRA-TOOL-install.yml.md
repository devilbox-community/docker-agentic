[Agent Tools: Overview](../../agentic_tools/README.md) |
[Agent Tools: `options.yml`](AGENT-TOOL-options.yml.md) |
Agent Tools: `install.yml`

---

<h2><img name="Documentation" title="Documentation" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> Contributor Documentation: Agent Tools</h2>



# Tool definition: `install.yml`

Agent tools each get their own Docker image. The `install.yml` defines how to
install the agent harness CLI. The Jinja2 template
(`.ansible/DOCKERFILES/Dockerfile-agentic.j2`) generates a 4-stage multi-stage
Dockerfile per tool: BUILDER → FINAL → TEST → FINAL-LABELS.


## Top level defines

| Yaml key  | Description                                                                                   |
|-----------|-----------------------------------------------------------------------------------------------|
| `check`   | Shell command that verifies the tool was installed correctly. Exits non-zero on failure.      |
| `all`     | Generic install block used for all builds. Agentic has no per-version axis; only `all` is used. |


### `check`

* Required: No
* Type: `str`

A shell command that runs in the TEST stage to verify the binary works.
Typically uses `--version` and greps for a version number.

Example:
```yaml
check: claude --version 2>&1 | grep -qE '[0-9]+\.[0-9]+'
```


## `all` block

Contains the installation instructions. All keys below live under `all:`.


### `type`

* Required: Yes
* Type: `str`
* Values: `custom` | `npm` | `pip` | `curl` | `apt`

Determines which install strategy the Jinja2 macros will use. Most agent
harness CLIs use `custom` since they have their own install scripts.

| Type     | Behaviour |
|----------|-----------|
| `custom` | Runs `command` as an arbitrary shell command (most common for agent CLIs) |
| `npm`    | `npm install -g <package>`, then symlinks binary |
| `pip`    | `pipx install <package>`, then copies binary from `/root/.local/bin/` |
| `curl`   | Runs `command` as a shell command (intended for curl-based installers) |
| `apt`    | `apt-get install -y <package>` |


### `command`

* Required: For `custom` and `curl` types
* Type: `str`

The shell command to install the tool. The macro wraps this in a `RUN set -eux`
block. The command should install the binary to `/opt/agentic-tools/<slug>/bin/`.

Example:
```yaml
  type: custom
  command: >-
    mkdir -p /opt/agentic-tools/claude-code/bin;
    curl -fsSL https://claude.ai/install.sh | bash;
    install -D -m 0755 "$(command -v claude)" /opt/agentic-tools/claude-code/bin/claude
```


### `package`

* Required: For `npm`, `pip`, `apt` types
* Type: `str`

The package name to install.

Example:
```yaml
  type: npm
  package: reasonix
```


### `binary`

* Required: No (defaults to the tool directory name)
* Type: `str`

The name of the binary that will be symlinked to `/usr/local/bin`.

Example:
```yaml
  type: npm
  package: reasonix
  binary: reasonix
```


### `version`

* Required: No
* Type: `str`

Version pin for npm/pip packages. Leave empty for latest.

Example:
```yaml
  version: "1.2.3"
```


### `build_dep` / `run_dep`

* Required: No
* Type: `list[str]`
* Empty: `[]`

Apt packages required at build time (`build_dep`) or runtime (`run_dep`).

Example:
```yaml
  build_dep: [libssl-dev]
  run_dep: [libssl3]
```


### `pre` / `post`

* Required: No
* Type: `str`

Shell commands to run before (`pre`) or after (`post`) the main install command.

Example:
```yaml
  type: curl
  command: curl -sS -L --fail "${TOOL_URL}" -o /usr/local/bin/tool
  pre: TOOL_URL="https://example.com/tool"
  post: chmod +x /usr/local/bin/tool
```
