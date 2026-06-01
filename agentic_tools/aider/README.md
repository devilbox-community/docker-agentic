# aider

AI pair programmer in your terminal — git-aware, multi-file edits across most frontier models.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| PyPI     | https://pypi.org/project/aider-chat/                             |
| Site     | https://aider.chat                                               |
| GitHub   | https://github.com/Aider-AI/aider                                |

## Authentication

**API-key (env vars).** Set one of `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `DEEPSEEK_API_KEY`, `GEMINI_API_KEY`, etc. — aider picks the provider from `--model` or `AIDER_MODEL`. Flow: api-key.

## Persistence

**host: cfg/agentic-aider/** → **container: /home/devilbox/.aider**

| Host                  | Container path             |
|-----------------------|----------------------------|
| `cfg/agentic-aider/`  | `/home/devilbox/.aider`    |

Holds chat history (`.aider.chat.history.md`), input history, and model cache.
