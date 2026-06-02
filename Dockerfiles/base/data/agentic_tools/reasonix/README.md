# DeepSeek Reasonix

Reasonix is a DeepSeek-based reasoning-agent CLI. This entry installs from the
upstream Git repository at image build time:

```
git clone --depth 1 https://github.com/esengine/DeepSeek-Reasonix /opt/agentic-tools/reasonix/src
python3 -m pip install --target /opt/agentic-tools/reasonix/lib /opt/agentic-tools/reasonix/src
```

A small bash wrapper is dropped at `/opt/agentic-tools/reasonix/bin/reasonix`
that sets `PYTHONPATH=/opt/agentic-tools/reasonix/lib` and execs
`python3 -m reasonix "$@"`. The Wave 8D runtime toggle symlinks this into
`/usr/local/bin` when enabled. See [toggle documentation](../../README.md#enabledisable-toggle).

| Platform | Url                                                  |
|----------|------------------------------------------------------|
| Upstream | https://github.com/esengine/DeepSeek-Reasonix        |
| DeepSeek | https://www.deepseek.com/                            |

## Authentication

Reasonix authenticates via a DeepSeek API key
(e.g. `DEEPSEEK_API_KEY`) or a config file under `~/.config/reasonix/`.

## Persistence

**host: cfg/agentic-reasonix/** → **container: /home/devilbox/.config/reasonix**

The directory `~/.config/reasonix/` (mapped to
`/home/devilbox/.config/reasonix`) is created at build time and should be
mounted as a volume to persist credentials and reasoning-agent state across
container restarts.

## Build-time fallback

If `https://github.com/esengine/DeepSeek-Reasonix` is unreachable (4xx/5xx)
during image build, the installer emits `WARNING reasonix upstream
unavailable` and drops a stub wrapper at
`/opt/agentic-tools/reasonix/bin/reasonix` that prints an availability notice
and exits 0. The image build never fails on upstream outages.
