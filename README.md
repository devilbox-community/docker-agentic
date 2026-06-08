# docker-agentic

A dedicated developer environment for AI coding agents and CLI tools. This container provides a stable, pre-configured workspace that integrates seamlessly with the Devilbox project to enable agentic workflows.

## Quick start

```bash
cd devilbox
./dvl.sh agent enable agentic
./dvl.sh agent up
./dvl.sh agent shell
```

Node.js is managed via nvm at `/opt/nvm` (default: LTS). Bun is available at `/usr/local/bin/bun`.

## Architecture

The project follows the multi-stage image pattern from `docker-php-fpm`:

| Stage | Image | Contents |
|-------|-------|----------|
| `base` | `devilboxcommunity/agentic:base` | Debian trixie-slim + system packages |
| `work` | `devilboxcommunity/agentic:work` | Base + runtimes (Go, nvm/Node, Bun, Python) + dev tools + extra tools |
| Per-agent | `devilboxcommunity/agentic:claude-code`, etc. | Work + single agent harness tool |

### Extra tools (built into work image)

These are shared spec/workflow utilities installed in the `:work` image and available to all per-agent images.

| Name | Type | Binary | Purpose |
|------|------|--------|---------|
| [openspec](extra_tools/openspec/) | npm | `openspec` | Spec-driven development workflow |
| [speckit](extra_tools/speckit/) | pip | `specify` | GitHub Spec Kit bootstrap CLI |

### Agentic tools (per-agent images)

Each agent harness CLI gets its own Docker image layered on top of `work`.
12 tools are auto-generated and auto-discovered by CI.

| Name | Type | Binary | Image tag |
|------|------|--------|-----------|
| [claude-code](agentic_tools/claude-code/) | custom | `claude` | `claude-code` |
| [codex](agentic_tools/codex/) | custom | `codex` | `codex` |
| [copilot](agentic_tools/copilot/) | custom | `copilot` | `copilot` |
| [droid](agentic_tools/factory/) | custom | `droid` | `droid` |
| [gemini](agentic_tools/gemini/) | npm | `gemini` | `gemini` |
| [kilo-code](agentic_tools/kilo-code/) | npm | `kilo` | `kilo-code` |
| [kimi](agentic_tools/kimi/) | custom | `kimi` | `kimi` |
| [kiro](agentic_tools/kiro/) | custom | `kiro-cli` | `kiro` |
| [opencode](agentic_tools/opencode/) | custom | `opencode` | `opencode` |
| [pi-coding-agent](agentic_tools/pi-coding-agent/) | custom | `pi` | `pi-coding-agent` |
| [qwen-code](agentic_tools/qwen-code/) | npm | `qwen` | `qwen-code` |
| [reasonix](agentic_tools/reasonix/) | npm | `reasonix` | `reasonix` |

## ENABLE/DISABLE toggle

Runtime toggle environment variables manage tool availability in the container:

- `AGENTIC_TOOLS_ENABLE` — Enables additional tools at startup.
- `AGENTIC_TOOLS_DISABLE` — Disables a tool that is enabled by default (disable wins on collision).

Toggle state is evaluated at the container entrypoint via `20-agentic-toggle.sh`. See the [Agentic tools toggle docs](../devilbox/docs/src/content/docs/getting-started/agentic-tools-toggle/) for full details.

## Build

```bash
make gen
make build STAGE=base
make build STAGE=work
make test STAGE=base
make lint
```

### Per-agent builds

```bash
make build STAGE=claude-code
make build STAGE=opencode
make rebuild STAGE=codex
make push STAGE=copilot
```

Arguments mirror `docker-php-fpm`:

- `STAGE` — `base`, `work`, or an agent tool name (`claude-code`, `codex`, `copilot`, `opencode`, `pi-coding-agent`, `reasonix`).
- `ARCH` — `linux/amd64` (default) or `linux/arm64`.
- `TAG`  — Optional suffix appended to the Docker tag.

## Adding a new tool

### Extra tool (shared, goes in base)

```bash
mkdir -p extra_tools/my-tool
# Create options.yml, install.yml, README.md
make gen
make build STAGE=base
```

### Agentic tool (per-agent image)

```bash
mkdir -p agentic_tools/my-agent
# Create options.yml, install.yml, README.md
make gen
make build STAGE=my-agent
```

## Integration with Devilbox

Integration is handled through the [compose override](https://github.com/devilbox/devilbox/blob/master/compose/docker-compose.override.yml-agentic) and `dvl agent` subcommands in the main Devilbox repository. Enable the service to add the `agentic` container to your stack.

## Authentication

See [doc/AUTH.md](doc/AUTH.md) for details on the host-to-container OAuth bridge and specific tool authentication flows.

## Persistence

Data stored in the following host directories survives `docker volume rm` and container updates:

- `cfg/agentic/claude/` maps to `/home/devilbox/.claude` (Claude Code configs and sessions)
- `cfg/agentic/codex/` maps to Codex state
- `cfg/agentic/copilot/` maps to GitHub Copilot credentials
- `cfg/agentic/opencode/` maps to `~/.config/opencode`
- `cfg/agentic/openspec/` maps to OpenSpec workspace
- `cfg/agentic/shared/` maps to `/home/devilbox/.shared` (shared env vars)

---

[LICENSE](LICENSE) | [CHANGELOG](CHANGELOG.md)
