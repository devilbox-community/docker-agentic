# Crush

Crush is Charm.sh's AI coding agent for the terminal. Real, actively maintained.

| Platform | Url                                                                                                |
|----------|----------------------------------------------------------------------------------------------------|
| Upstream | https://charm.sh/                                                                                  |
| GitHub   | https://github.com/charmbracelet/crush                                                             |
| Release  | https://github.com/charmbracelet/crush/releases/latest (Debian `.deb`, version queried via GH API) |

Installed from the official Debian `.deb` published in GitHub Releases (no
npm, no brew). The build step queries the GH API for the latest `tag_name`,
downloads `crush_<VER>_amd64.deb`, `dpkg -i`s it, then relocates the binary
to `/opt/agentic-tools/crush/bin/crush`. Fallback: `go install` (Go from
BASE image) when the release probe fails.

Default-toggle: **OFF** — symlinked into `/usr/local/bin` at runtime. See [toggle documentation](../../README.md#enabledisable-toggle).

## Authentication

Crush uses API keys for the underlying LLM providers. Set them as environment
variables (e.g. `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`) or via Crush's interactive
setup — credentials and provider config are written under `~/.config/crush/`. Flow: api-key.

## Persistence

**host: cfg/agentic-crush/** → **container: /home/devilbox/.config/crush**

The directory `~/.config/crush/` (mapped to `/home/devilbox/.config/crush`) holds
provider credentials, session history and agent configuration. Mount it as a volume
to persist across container restarts.
