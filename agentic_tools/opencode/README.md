# opencode

Open-source, model-agnostic terminal agent. Plug in Anthropic, OpenAI, OpenRouter, local models, etc. via a single TUI.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| Install  | `curl -fsSL https://opencode.ai/install \| bash` (native)        |
| Site     | https://opencode.ai                                              |
| GitHub   | https://github.com/sst/opencode                                  |

Installed via the official native installer (no npm). Binary is relocated to
`/opt/agentic-tools/opencode/bin/opencode` at build.

Default-toggle: **ON** — symlinked into `/usr/local/bin` at runtime. See [toggle documentation](../../README.md#enabledisable-toggle).

## Authentication

**Callback OAuth (per provider).** Run `opencode auth login` and pick a provider; the CLI launches a browser callback flow and writes tokens to `auth.json`. Provider API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, …) are also honored. Flow: callback.

## Persistence

**host: cfg/agentic-opencode/** → **container: /home/devilbox/.config/opencode**

| Host                    | Container path                            |
|-------------------------|-------------------------------------------|
| `cfg/agentic-opencode/` | `/home/devilbox/.config/opencode`         |

Holds `auth.json`, sessions, and per-project config.
