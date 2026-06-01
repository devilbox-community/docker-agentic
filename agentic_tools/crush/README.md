# Crush

Crush is Charm.sh's AI coding agent for the terminal. Real, actively maintained.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| Upstream | https://charm.sh/                                                |
| GitHub   | https://github.com/charmbracelet/crush                           |
| Install  | https://raw.githubusercontent.com/charmbracelet/crush/install.sh |

## Authentication

Crush uses API keys for the underlying LLM providers. Set them as environment
variables (e.g. `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`) or via Crush's interactive
setup — credentials and provider config are written under `~/.config/crush/`. Flow: api-key.

## Persistence

**host: cfg/agentic-crush/** → **container: /home/devilbox/.config/crush**

The directory `~/.config/crush/` (mapped to `/home/devilbox/.config/crush`) holds
provider credentials, session history and agent configuration. Mount it as a volume
to persist across container restarts.
