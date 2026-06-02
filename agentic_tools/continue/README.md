# continue

Continue.dev — open-source AI code assistant CLI companion to the
Continue VS Code / JetBrains extensions.

| Platform | Url                                                           |
|----------|---------------------------------------------------------------|
| Install  | `curl -fsSL https://continue.dev/install.sh \| bash` (native) |
| GitHub   | https://github.com/continuedev/continue                       |
| Docs     | https://docs.continue.dev/                                    |

Installed via the official native installer (bundles its own Node runtime;
no npm). Binary is relocated to `/opt/agentic-tools/continue/bin/continue`
at build.

Default-toggle: **OFF** — symlinked into `/usr/local/bin` at runtime. See [toggle documentation](../../README.md#enabledisable-toggle).

## Authentication

Continue reads provider API keys from its config file (`~/.continue/config.json`)
or from env vars such as `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`. Set these on
the `devilboxcommunity/agentic` container or commit them to the config file. Flow: api-key.

## Persistence

**host: cfg/agentic-continue/** → **container: /home/devilbox/.continue**

Configuration, models, and assistant state persist at `/home/devilbox/.continue/`.
Mount this path on the host to retain settings across container restarts.
