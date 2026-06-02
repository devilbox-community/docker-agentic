# Gemini CLI

Google's official agentic Gemini CLI. Distributed via npm — installed in an
isolated prefix to satisfy the Wave 8 binary-relocation pattern.

## Overview

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| NPM      | https://www.npmjs.com/package/@google/gemini-cli                 |
| Docs     | https://ai.google.dev/gemini-api/docs/                           |

Default-toggle: **ON** — installed by default and symlinked into `/usr/local/bin`
at runtime by `data/startup.1.d/20-agentic-toggle.sh` (Wave 8D).

## Install Source

User-directed npm install with isolated prefix:

```bash
npm install -g --prefix /opt/agentic-tools/gemini @google/gemini-cli
```

- Build-time probe: `npm view @google/gemini-cli version` — skip-with-warning on failure.
- `--prefix /opt/agentic-tools/gemini` lands the binary at
  `/opt/agentic-tools/gemini/bin/gemini` directly — no relocation needed.
- Runtime symlink to `/usr/local/bin/gemini` is managed by the Wave 8D startup toggle.
  See [toggle documentation](../../README.md#enabledisable-toggle).

## Authentication

Auth Setup: requires the `GEMINI_API_KEY` environment variable to be exported in
the container (e.g. via `devilbox/env-example`) **before** running `gemini`.
OAuth login (`gemini auth login`) is also supported and persists tokens to
`~/.config/gemini/`.

```bash
export GEMINI_API_KEY=...        # required prereq for non-interactive use
gemini --version
```

## Persistence

**host: cfg/agentic-gemini/** → **container: /home/devilbox/.config/gemini**

| Host                          | Container path                          |
|-------------------------------|-----------------------------------------|
| `cfg/agentic-gemini/`         | `/home/devilbox/.config/gemini`         |

Stores OAuth tokens, project history, and per-session caches.
