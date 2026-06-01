# llm (Datasette)

Simon Willison's `llm` — a CLI for interacting with LLMs, supporting OpenAI, Anthropic,
local models, and plugins. Real, actively maintained.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| PyPI     | https://pypi.org/project/llm/                                    |
| Docs     | https://llm.datasette.io/                                        |
| GitHub   | https://github.com/simonw/llm                                    |

## Authentication

Set provider API keys via `llm keys set <provider>`, e.g.:

```bash
llm keys set openai
llm keys set anthropic
```

Keys are stored in the persisted config directory. Flow: api-key.

## Persistence

**host: cfg/agentic-llm/** → **container: /home/devilbox/.config/io.datasette.llm**

The directory `~/.config/io.datasette.llm/` (mapped to
`/home/devilbox/.config/io.datasette.llm`) holds keys, logged prompts, templates and
installed plugins. Mount it as a volume to persist across container restarts.
