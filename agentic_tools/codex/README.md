# Codex CLI

OpenAI's official terminal agent — runs Codex/GPT models with sandboxed shell, file edit, and patch tools.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| Install  | `curl -fsSL https://chatgpt.com/codex/install.sh \| sh` (native) |
| GitHub   | https://github.com/openai/codex                                  |

Installed via the official native installer (no npm). Binary is relocated to
`/opt/agentic-tools/codex/bin/codex` at build.

Default-toggle: **ON** — symlinked into `/usr/local/bin` at runtime. See [toggle documentation](../../README.md#enabledisable-toggle).

## Authentication

**Hybrid: api-key or device-code.** Set `OPENAI_API_KEY` env var, or run `codex login` to use ChatGPT-account device-flow OAuth. Tokens persist in `~/.codex/`. Flow: hybrid.

## Persistence

**host: cfg/agentic-codex/** → **container: /home/devilbox/.codex**

| Host                  | Container path             |
|-----------------------|----------------------------|
| `cfg/agentic-codex/`  | `/home/devilbox/.codex`    |

Holds auth tokens, config.toml, and session transcripts.
