# OpenClaw

OpenClaw is an open-source agentic coding CLI distributed via a native `install.sh`
bash installer (no npm dependency).

## Overview

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| Upstream | https://openclaw.ai/                                             |
| Installer| https://openclaw.ai/install.sh                                   |

Default-toggle: **ON** — installed by default and symlinked into `/usr/local/bin`
at runtime by `data/startup.1.d/20-agentic-toggle.sh` (Wave 8D).

## Install Source

Native bash installer (`curl -fsSL https://openclaw.ai/install.sh | bash`).

- Build-time probe: `curl -fsI https://openclaw.ai/install.sh` — skip-with-warning on 4xx.
- Binary relocated to `/opt/agentic-tools/openclaw/bin/openclaw` after install.
- Runtime symlink to `/usr/local/bin/openclaw` is created/removed by the
  Wave 8D startup toggle based on `AGENTIC_TOOLS_ENABLE` / `AGENTIC_TOOLS_DISABLE`.
  See [toggle documentation](../../README.md#enabledisable-toggle).

## Authentication

Auth Setup: device-code OAuth on first `openclaw` run, or `OPENCLAW_API_KEY` env var.
Credentials persisted under `~/.config/openclaw/`.

## Persistence

**host: cfg/agentic-openclaw/** → **container: /home/devilbox/.config/openclaw**

| Host                          | Container path                           |
|-------------------------------|------------------------------------------|
| `cfg/agentic-openclaw/`       | `/home/devilbox/.config/openclaw`        |

Mount as volume to persist credentials and session history across container rebuilds.
