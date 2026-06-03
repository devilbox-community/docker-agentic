# GitHub Copilot CLI

GitHub's standalone `copilot` CLI — suggest and explain shell commands using Copilot, straight from the terminal.

Default-toggle: **ON** — symlinked into `/usr/local/bin` at runtime. See [toggle documentation](../../README.md#enabledisable-toggle).

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| CLI      | https://github.com/github/copilot-cli                            |

## Authentication

**Device-code OAuth** via the Copilot CLI. Requires an active GitHub Copilot subscription on the account. Flow: device-code.

## Persistence

**host: cfg/agentic-copilot/** → **container: /home/devilbox/.config/copilot**

| Host                    | Container path                  |
|-------------------------|---------------------------------|
| `cfg/agentic-copilot/`  | `/home/devilbox/.config/copilot`|

Stores Copilot CLI authentication state.
