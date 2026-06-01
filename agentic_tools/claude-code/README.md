# Claude Code

Anthropic's official agentic coding CLI. Runs an interactive agent that reads, edits, and executes against your repo via the Anthropic API.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| NPM      | https://www.npmjs.com/package/@anthropic-ai/claude-code          |
| Docs     | https://docs.claude.com/en/docs/claude-code                      |

## Authentication

**Device-code OAuth.** Run `claude` and follow the printed URL on the host browser; the CLI persists tokens locally — no API key needed for Pro/Max plans. `ANTHROPIC_API_KEY` env var also supported.

## Persistence

| Host                          | Container path                  |
|-------------------------------|---------------------------------|
| `cfg/agentic-claude/`         | `/home/devilbox/.claude`        |

Stores `.credentials.json`, `.claude.json`, project history. Survives container rebuilds.
