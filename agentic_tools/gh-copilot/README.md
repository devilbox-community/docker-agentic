# GitHub Copilot CLI (gh extension)

GitHub's `gh copilot` extension — suggest and explain shell commands using Copilot, straight from the terminal.

Default-toggle: **ON** — symlinked into `/usr/local/bin` at runtime. See [toggle documentation](../../README.md#enabledisable-toggle).

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| GH CLI   | https://cli.github.com                                           |
| Ext      | https://github.com/github/gh-copilot                             |

## Authentication

**Device-code OAuth** via `gh auth login` (web flow prints a one-time code). Requires an active GitHub Copilot subscription on the account. Flow: device-code.

## Persistence

**host: cfg/agentic-copilot/** → **container: /home/devilbox/.config/gh**

| Host                    | Container path                  |
|-------------------------|---------------------------------|
| `cfg/agentic-copilot/`  | `/home/devilbox/.config/gh`     |

Stores `hosts.yml` (oauth token) and gh extension state.
