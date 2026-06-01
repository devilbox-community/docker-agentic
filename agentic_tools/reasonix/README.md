# DeepSeek Reasonix

A DeepSeek "Reasonix" reasoning-agent CLI is **not currently published** as a standalone
distributable. This entry ships a stub binary so the image build remains green and the
persistence directory is reserved for when an upstream release lands.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| Upstream | https://www.deepseek.com/                                        |
| Models   | https://huggingface.co/deepseek-ai                               |

## Authentication

When upstream publishes a CLI, expected auth is via API key (e.g. `DEEPSEEK_API_KEY`)
or a config file under `~/.config/reasonix/`. Flow: stub.

## Persistence

**host: cfg/agentic-reasonix/** → **container: /home/devilbox/.config/reasonix**

The directory `~/.config/reasonix/` (mapped to `/home/devilbox/.config/reasonix`) is
created at build time and should be mounted as a volume to persist credentials and
reasoning-agent state across container restarts.

Status: STUB

> **Stub notice**: invoking `reasonix` currently prints an availability notice and exits 0.
