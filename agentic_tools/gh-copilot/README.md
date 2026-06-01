# GitHub Copilot CLI (gh extension)

GitHub's `gh copilot` extension — suggest and explain shell commands using Copilot, straight from the terminal.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| GH CLI   | https://cli.github.com                                           |
| Ext      | https://github.com/github/gh-copilot                             |

## Authentication

**Device-code OAuth** via `gh auth login` (web flow prints a one-time code). Requires an active GitHub Copilot subscription on the account.

## Persistence

| Host                    | Container path                  |
|-------------------------|---------------------------------|
| `cfg/agentic-copilot/`  | `/home/devilbox/.config/gh`     |

Stores `hosts.yml` (oauth token) and gh extension state.
