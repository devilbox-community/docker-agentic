# opencode

Open-source, model-agnostic terminal agent. Plug in Anthropic, OpenAI, OpenRouter, local models, etc. via a single TUI.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| NPM      | https://www.npmjs.com/package/opencode-ai                        |
| Site     | https://opencode.ai                                              |
| GitHub   | https://github.com/sst/opencode                                  |

## Authentication

**Callback OAuth (per provider).** Run `opencode auth login` and pick a provider; the CLI launches a browser callback flow and writes tokens to `auth.json`. Provider API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, …) are also honored.

## Persistence

| Host                    | Container path                            |
|-------------------------|-------------------------------------------|
| `cfg/agentic-opencode/` | `/home/devilbox/.config/opencode`         |

Holds `auth.json`, sessions, and per-project config.
