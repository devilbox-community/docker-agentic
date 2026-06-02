# docker-agentic

A dedicated developer environment for AI coding agents and CLI tools. This container provides a stable, pre-configured workspace that integrates seamlessly with the Devilbox project to enable agentic workflows.

## Quick start

```bash
cd devilbox
./dvl.sh agent enable
./dvl.sh agent up
./dvl.sh agent shell
```

Node.js is managed via nvm at `/opt/nvm` (default: LTS). Bun is available at `/usr/local/bin/bun`.

## Bundled CLI tools

19 tools are included. 11 tools are enabled by default (see `AGENTIC_TOOLS_ENABLE` below), while 8 are opt-in.

| Name | Install type | Default | Auth method | Persistence path |
|---|---|---|---|---|
| aider | native bash | OFF | api-key | `cfg/agentic-aider/` |
| claude-code | native bash | ON | device-code | `cfg/agentic-claude/` |
| cline | npm | OFF | host-ide | `cfg/agentic-cline/` |
| codewhale | pip | ON | api-key | `cfg/agentic-codewhale/` |
| codex | native bash | ON | device-code | `cfg/agentic-codex/` |
| continue | native bash | OFF | host-ide | `cfg/agentic-continue/` |
| crush | native bash | OFF | api-key | `cfg/agentic-crush/` |
| cursor | native bash | ON | host-ide | `cfg/agentic-cursor/` |
| gemini | npm | ON | api-key | `cfg/agentic-gemini/` |
| gh-copilot | gh-extension | ON | device-code | `cfg/agentic-copilot/` |
| goose | native bash | OFF | api-key | `cfg/agentic-goose/` |
| hermes | native bash | ON | api-key | `cfg/agentic-hermes/` |
| llm | native bash | OFF | api-key | `cfg/agentic-llm/` |
| multica | native bash | OFF | api-key | `cfg/agentic-multica/` |
| openclaw | native bash | ON | callback | `cfg/agentic-openclaw/` |
| opencode | native bash | ON | callback | `cfg/agentic-opencode/` |
| pi-coding-agent | npm | ON | api-key | `cfg/agentic-pi-coding-agent/` |
| qwen-code | native bash | OFF | api-key | `cfg/agentic-qwen-code/` |
| reasonix | pip | ON | api-key | `cfg/agentic-reasonix/` |

## ENABLE/DISABLE toggle

Wave 8 introduces a runtime toggle via environment variables to manage tool availability. 11 tools are enabled by default (claude-code, opencode, codex, cursor, codewhale, reasonix, hermes, openclaw, pi-coding-agent, gh-copilot, gemini).

- `AGENTIC_TOOLS_ENABLE=aider,crush` — Enables these additional tools at startup.
- `AGENTIC_TOOLS_DISABLE=gh-copilot` — Disables a tool that is enabled by default.

Toggle state is evaluated at the container entrypoint. See `Dockerfiles/base/data/agentic_tools/_defaults.yml` for the canonical list of defaults.

## Build

```bash
make gen
make build STAGE=base VERSION=latest
make build STAGE=work VERSION=latest
make test STAGE=work VERSION=latest
make lint
```

Arguments mirror `docker-php-fpm`:

- `STAGE`   — `base` or `work` (required for `build`/`rebuild`/`push`/`test`).
- `VERSION` — `latest` or `stable` (defaults to `latest`).
- `ARCH`    — `linux/amd64` (default) or `linux/arm64`.
- `TAG`     — Optional suffix appended to the Docker tag.

The legacy `make build-base` / `make build-work [RELEASE=...]` targets still
work but print a deprecation warning; they forward to `make build STAGE=...`.

## Integration with Devilbox

Integration is handled through the [compose override](https://github.com/devilbox/devilbox/blob/master/compose/docker-compose.override.yml-agentic) and `dvl agent` subcommands in the main Devilbox repository. Enable the service to add the `agentic` container to your stack.

## Authentication

See [doc/AUTH.md](doc/AUTH.md) for details on the host-to-container OAuth bridge and specific tool authentication flows.

## Persistence

Data stored in the following host directories survives `docker volume rm` and container updates:

- `cfg/agentic-home/` maps to `/home/devilbox` (history, gitconfig).
- `cfg/agentic-shared/` maps to `/home/devilbox/.shared` (environment variables).
- Tool-specific directories (e.g., `cfg/agentic-aider/`) map to their respective config paths.

---

[LICENSE](LICENSE) | [CHANGELOG](CHANGELOG.md)
