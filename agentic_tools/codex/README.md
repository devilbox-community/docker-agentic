# Codex CLI

OpenAI's official terminal agent — runs Codex/GPT models with sandboxed shell, file edit, and patch tools.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| NPM      | https://www.npmjs.com/package/@openai/codex                      |
| GitHub   | https://github.com/openai/codex                                  |

## Authentication

**Hybrid: api-key or device-code.** Set `OPENAI_API_KEY` env var, or run `codex login` to use ChatGPT-account device-flow OAuth. Tokens persist in `~/.codex/`. Flow: hybrid.

## Persistence

**host: cfg/agentic-codex/** → **container: /home/devilbox/.codex**

| Host                  | Container path             |
|-----------------------|----------------------------|
| `cfg/agentic-codex/`  | `/home/devilbox/.codex`    |

Holds auth tokens, config.toml, and session transcripts.
