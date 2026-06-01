# Hermes Agent

Hermes is the official agentic CLI from Nous Research. This entry installs
from the upstream install script at image build time:

```
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

The resulting `hermes` binary is relocated to
`/opt/agentic-tools/hermes/bin/hermes`. The Wave 8D runtime toggle symlinks
this into `/usr/local/bin` when enabled. See [toggle documentation](../../README.md#enabledisable-toggle).

| Platform | Url                                                  |
|----------|------------------------------------------------------|
| Upstream | https://nousresearch.com/                            |
| Install  | https://hermes-agent.nousresearch.com/install.sh     |
| Models   | https://huggingface.co/NousResearch                  |

## Authentication

Hermes authenticates via a Nous Research API key (e.g. `NOUS_API_KEY`) or a
config file under `~/.config/hermes/`. Provide the API key as an environment
variable on container start.

## Persistence

**host: cfg/agentic-hermes/** → **container: /home/devilbox/.config/hermes**

The directory `~/.config/hermes/` (mapped to `/home/devilbox/.config/hermes`)
is created at build time and should be mounted as a volume to persist
credentials and agent state across container restarts.

## Build-time fallback

If `https://hermes-agent.nousresearch.com/install.sh` is unreachable
(4xx/5xx) during image build, the installer emits
`WARNING hermes upstream unavailable` and drops a stub at
`/opt/agentic-tools/hermes/bin/hermes` that prints an availability notice and
exits 0. The image build never fails on upstream outages.
