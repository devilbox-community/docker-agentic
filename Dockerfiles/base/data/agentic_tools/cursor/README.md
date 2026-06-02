# cursor

Cursor — AI-first IDE. This entry installs the official Cursor **CLI**
(`cursor-agent`) only — **not** the desktop IDE. The CLI is fetched at image
build time from `https://cursor.com/install` and relocated to
`/opt/agentic-tools/cursor/bin/cursor-agent`. The Wave 8D runtime toggle
symlinks this into `/usr/local/bin` when enabled. See [toggle documentation](../../README.md#enabledisable-toggle).

| Platform | Url                              |
|----------|----------------------------------|
| Website  | https://cursor.com               |
| Docs     | https://docs.cursor.com          |
| Install  | https://cursor.com/install       |

## Authentication

The CLI authenticates against your Cursor account. Run `cursor-agent login`
inside the container; tokens are persisted under `/home/devilbox/.cursor/`.

## Persistence

**host: cfg/agentic-cursor/** → **container: /home/devilbox/.cursor**

Configuration persists at `/home/devilbox/.cursor/`. Mount this path on the
host to retain credentials and settings across container restarts.

## Build-time fallback

If `https://cursor.com/install` returns 4xx/5xx during image build, the
installer emits `WARNING cursor upstream unavailable` and drops a stub at
`/opt/agentic-tools/cursor/bin/cursor-agent` that prints an availability
notice and exits 0. The image build never fails on upstream outages.
