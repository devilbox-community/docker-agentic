# docker-agentic

A dedicated developer environment for AI coding agents and CLI tools. This container provides a stable, pre-configured workspace that integrates seamlessly with the Devilbox project to enable agentic workflows.

## Quick start

```bash
cd devilbox
./dvl agent enable
./dvl agent up
./dvl agent shell
```

## Bundled CLI tools

| Name | Install type | Auth method | Persistence path |
|---|---|---|---|
| aider | pip | api-key | `cfg/agentic-aider/` |
| claude-code | npm | device-code | `cfg/agentic-claude/` |
| cline | custom | host-ide | `cfg/agentic-cline/` |
| codewhale | custom | api-key | `cfg/agentic-codewhale/` |
| codex | npm | device-code | `cfg/agentic-codex/` |
| continue | npm | host-ide | `cfg/agentic-continue/` |
| crush | npm | api-key | `cfg/agentic-crush/` |
| cursor | custom | host-ide | `cfg/agentic-cursor/` |
| gh-copilot | custom | device-code | `cfg/agentic-copilot/` |
| goose | curl | api-key | `cfg/agentic-goose/` |
| hermes | custom | api-key | `cfg/agentic-hermes/` |
| llm | pip | api-key | `cfg/agentic-llm/` |
| opencode | npm | callback | `cfg/agentic-opencode/` |
| qwen-code | npm | api-key | `cfg/agentic-qwen-code/` |
| reasonix | custom | api-key | `cfg/agentic-reasonix/` |

## Build

```bash
make generate
make build-base RELEASE=latest
make build-work RELEASE=latest
make test
make lint
```

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
