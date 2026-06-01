# Multica CLI

Multica is an internal agentic stack (Go API + Postgres + uploads service). This
entry packages the **CLI portion only** — the full compose stack (`multica-api`,
`multica-db`, `multica-uploads`) lands in Wave 8F1 as a separate compose override.

## Overview

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| Upstream | internal / sibling repo                                          |
| Status   | default-OFF; requires sibling repo bind-mount at build time      |

Default-toggle: **OFF** — NOT symlinked into `/usr/local/bin` unless the user
explicitly enables it via `AGENTIC_TOOLS_ENABLE=multica` (Wave 8D). See
[toggle documentation](../../README.md#enabledisable-toggle).

## Install Source

Source-built from a sibling-repo bind mount at build time:

```dockerfile
ARG MULTICA_SRC=/workspace/multica
# build context must bind-mount the multica repo at /workspace/multica
```

Install script behaviour:

1. Reads `MULTICA_SRC` (defaults to `/workspace/multica`).
2. If `$MULTICA_SRC/apps/cli` exists, runs:
   ```bash
   cd "$MULTICA_SRC/apps/cli" && \
     go build -o /opt/agentic-tools/multica/bin/multica ./cmd/multica
   ```
3. If the sibling repo is absent, installs a stub binary that prints a
   warning and exits 0 (build remains green; CLI is optional).

**Important**: multica is the only tool that requires a sibling repository to be
present at build time. CI builds without `MULTICA_SRC` mounted will install the
stub; this is expected.

## Authentication

Auth Setup: the CLI talks to a local `multica-api` (default
`http://172.16.238.40:3001`) deployed by the Wave 8F1 compose override. No
external API keys are required for the CLI itself.

## Persistence

**host: cfg/agentic-multica/** → **container: /home/devilbox/.config/multica**

| Host                          | Container path                           |
|-------------------------------|------------------------------------------|
| `cfg/agentic-multica/`        | `/home/devilbox/.config/multica`         |

Stores CLI session state and API endpoint configuration. Postgres data,
uploads, and API state are persisted by the Wave 8F1 compose stack under
`cfg/multica-db/`, `cfg/multica-uploads/`, and `cfg/multica-api/`.
