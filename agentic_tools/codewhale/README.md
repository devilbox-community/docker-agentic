# Codewhale

Codewhale is referenced in agentic-coding research but has **no publicly available CLI
distribution** at the time of this build. This entry ships a stub binary that prints an
availability notice so the image build remains green and the persistence directory is
reserved for a future release.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| Status   | Research / not publicly distributed                              |

## Authentication

Unknown — to be defined when (if) upstream publishes a CLI. Likely API key based,
configured under `~/.config/codewhale/`.

## Persistence

The directory `~/.config/codewhale/` (mapped to `/home/devilbox/.config/codewhale`) is
created at build time and should be mounted as a volume to persist any future
credentials or agent state.

> **Stub notice**: invoking `codewhale` currently prints an availability notice and exits 0.
