# Hermes Agent

Hermes is an agentic LLM from Nous Research. A standalone public `hermes` CLI is **not
currently published**; this entry ships a stub binary so the image build remains green and
the persistence path is reserved for when an official release lands.

| Platform | Url                                                              |
|----------|------------------------------------------------------------------|
| Upstream | https://nousresearch.com/                                        |
| Models   | https://huggingface.co/NousResearch                              |

## Authentication

When an upstream CLI is released, expected auth is via API key environment variable
(e.g. `NOUS_API_KEY`) or a config file under `~/.config/hermes/`.

## Persistence

The directory `~/.config/hermes/` (mapped to `/home/devilbox/.config/hermes`) is
created at build time and should be mounted as a volume to persist credentials and
agent state across container restarts.

> **Stub notice**: invoking `hermes` currently prints an availability notice and exits 0.
