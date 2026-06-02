# Pi Coding Agent

Pi is an agentic coding CLI from Earendil Works. Distributed via an upstream
`install.sh` script that internally `npm install`s `@earendil-works/pi-coding-agent`.

## Overview

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| Upstream | https://pi.dev/                                                  |
| Installer| https://pi.dev/install.sh                                        |
| NPM      | https://www.npmjs.com/package/@earendil-works/pi-coding-agent    |

Default-toggle: **ON** — installed by default and symlinked into `/usr/local/bin`
at runtime by `data/startup.1.d/20-agentic-toggle.sh` (Wave 8D).

## Install Source

Official upstream `install.sh` (`curl -fsSL https://pi.dev/install.sh | sh`). The
script is a thin wrapper that delegates to `npm install -g`. We follow the
user-directed install path rather than calling npm directly so future installer
changes (telemetry opt-out, plugin scaffolding, etc.) Just Work.

- Build-time probe: `curl -fsI https://pi.dev/install.sh` — skip-with-warning on 4xx.
- Binary relocated to `/opt/agentic-tools/pi-coding-agent/bin/pi` after install.
- Runtime symlink to `/usr/local/bin/pi` is managed by the Wave 8D startup toggle.
  See [toggle documentation](../../README.md#enabledisable-toggle).

## Authentication

Auth Setup: requires the `PI_API_KEY` environment variable to be exported in the
container (e.g. via `devilbox/env-example`) **before** running `pi`. No interactive
device-code flow is available at this time.

```bash
export PI_API_KEY=...           # required prereq
pi --version
```

## Persistence

**host: cfg/agentic-pi/** → **container: /home/devilbox/.config/pi**

| Host                          | Container path                      |
|-------------------------------|-------------------------------------|
| `cfg/agentic-pi/`             | `/home/devilbox/.config/pi`         |

Stores per-project session state and any future cached auth material.
