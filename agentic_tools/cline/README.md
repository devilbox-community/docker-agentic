# cline

Cline (formerly Claude Dev) — autonomous coding agent shipped as a VS Code extension.
No standalone CLI exists; this container installs a stub that points users to VS Code
and preserves the on-disk configuration directory.

| Platform   | Url                                                  |
|------------|------------------------------------------------------|
| GitHub     | https://github.com/cline/cline                       |
| Marketplace| https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev |

## Authentication

Authentication is configured inside the Cline VS Code extension on the host
(API keys for Anthropic, OpenAI, OpenRouter, etc.). No env vars are read by
the container stub. Flow: stub.

## Persistence

**host: cfg/agentic-cline/** → **container: /home/devilbox/.config/cline**

Configuration persists at `/home/devilbox/.config/cline/`. Mount this path on
the host (or share it with the VS Code extension data dir) to retain settings.

Status: STUB
