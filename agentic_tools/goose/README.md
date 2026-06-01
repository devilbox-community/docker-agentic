# goose

Block's goose — open-source AI agent for software engineering.

| Platform | Url                                       |
|----------|-------------------------------------------|
| GitHub   | https://github.com/block/goose            |
| Docs     | https://block.github.io/goose/            |

## Authentication

Goose uses API keys for LLM providers. Set one of:

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GOOGLE_API_KEY`

Pass via Docker env on the `devilboxcommunity/agentic` container, or run `goose configure` interactively.

## Persistence

Configuration and session data persist at `/home/devilbox/.config/goose/`.
Mount this path on the host to retain profiles across container restarts.
