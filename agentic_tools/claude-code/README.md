# Claude Code

Anthropic's official agentic coding CLI. Runs an interactive agent that reads, edits, and executes against your repo via the Anthropic API.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| Install  | `curl -fsSL https://claude.ai/install.sh \| bash` (native)       |
| Docs     | https://docs.claude.com/en/docs/claude-code                      |

Installed via the official native installer (no npm). Binary is relocated to
`/opt/agentic-tools/claude-code/bin/claude` at build; Wave 8D's runtime toggle
symlinks it into `/usr/local/bin/claude` when the tool is enabled. See
[toggle documentation](../../README.md#enabledisable-toggle).

## Authentication

**Device-code OAuth.** Run `claude` and follow the printed URL on the host browser; the CLI persists tokens locally — no API key needed for Pro/Max plans. `ANTHROPIC_API_KEY` env var also supported. Flow: device-code.

## Persistence

**host: cfg/agentic-claude/** → **container: /home/devilbox/.claude**

| Host                          | Container path                  |
|-------------------------------|---------------------------------|
| `cfg/agentic-claude/`         | `/home/devilbox/.claude`        |

Stores `.credentials.json`, `.claude.json`, project history. Survives container rebuilds.
