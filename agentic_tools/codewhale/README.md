# Codewhale

CodeWhale is an open-source agentic coding CLI. This entry installs from the
upstream Git repository at image build time:

```
git clone --depth 1 https://github.com/Hmbown/CodeWhale /opt/agentic-tools/codewhale/src
python3 -m pip install --target /opt/agentic-tools/codewhale/lib /opt/agentic-tools/codewhale/src
```

A small bash wrapper is dropped at `/opt/agentic-tools/codewhale/bin/codewhale`
that sets `PYTHONPATH=/opt/agentic-tools/codewhale/lib` and execs
`python3 -m codewhale "$@"`. The Wave 8D runtime toggle symlinks this into
`/usr/local/bin` when enabled. See [toggle documentation](../../README.md#enabledisable-toggle).

| Platform | Url                                       |
|----------|-------------------------------------------|
| Upstream | https://github.com/Hmbown/CodeWhale       |

## Authentication

CodeWhale uses an API key (typically `OPENAI_API_KEY` or model-provider
specific). Configure via environment variable or a config file under
`~/.config/codewhale/`.

## Persistence

**host: cfg/agentic-codewhale/** → **container: /home/devilbox/.config/codewhale**

The directory `~/.config/codewhale/` (mapped to
`/home/devilbox/.config/codewhale`) is created at build time and should be
mounted as a volume to persist credentials and agent state.

## Build-time fallback

If `https://github.com/Hmbown/CodeWhale` is unreachable (4xx/5xx) during image
build, the installer emits `WARNING codewhale upstream unavailable` and drops
a stub wrapper at `/opt/agentic-tools/codewhale/bin/codewhale` that prints an
availability notice and exits 0. The image build never fails on upstream
outages.
