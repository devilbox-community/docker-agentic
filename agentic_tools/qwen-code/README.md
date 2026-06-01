# qwen-code

Qwen Code — Alibaba's coding agent CLI built on the Qwen models, forked from
Gemini CLI and adapted for Qwen3-Coder.

| Platform | Url                                              |
|----------|--------------------------------------------------|
| NPM      | https://www.npmjs.com/package/@qwen-code/qwen-code |
| GitHub   | https://github.com/QwenLM/qwen-code              |

## Authentication

Qwen Code reads `DASHSCOPE_API_KEY` (Alibaba Cloud Model Studio) or
OpenAI-compatible env vars (`OPENAI_API_KEY`, `OPENAI_BASE_URL`,
`OPENAI_MODEL`). Set these on the `devilboxcommunity/agentic` container. Flow: api-key.

## Persistence

**host: cfg/agentic-qwen-code/** → **container: /home/devilbox/.qwen**

Configuration and session state persist at `/home/devilbox/.qwen/`. Mount
this path on the host to retain settings across container restarts.
