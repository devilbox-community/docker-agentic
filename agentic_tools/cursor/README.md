# cursor

Cursor — AI-first IDE. No first-party Linux CLI is published; this container
ships a `cursor-agent` stub that documents host-side usage and preserves the
on-disk configuration directory.

| Platform | Url                              |
|----------|----------------------------------|
| Website  | https://cursor.com               |
| Docs     | https://docs.cursor.com          |

## Authentication

Authentication happens inside the Cursor desktop application on the host
(Cursor account, model API keys). The container stub does not read any env vars.

## Persistence

Configuration persists at `/home/devilbox/.cursor/`. Mount this path on the
host (or share it with your Cursor profile) to retain settings across
container restarts.
