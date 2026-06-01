# Agentic OAuth bridge

The agentic container cannot open the host desktop browser directly. Wave 5
bridges that gap with two small pieces:

1. `/usr/local/bin/dvl-open-host` inside the container writes a URL to the FIFO
   at `/var/run/dvl-oauth/url`.
2. `devilbox/.devilbox/oauth-bridge.sh` on the host polls that FIFO and opens
   the URL with `open`, `xdg-open`, or `cmd.exe /c start`.

Run supported auth flows with:

```sh
cd devilbox
./dvl agent auth <tool>
```

## Decision tree

### Device-code flow

Use this when the CLI prints a URL and one-time code. The container prints the
code in your terminal, and the bridge opens the URL in the host browser. You
enter the code on the host browser, then the CLI writes tokens into its mounted
`cfg/agentic-*` directory.

Examples: `claude-code`, `gh-copilot`, `codex` when it chooses device auth.

### Callback flow

Use this when the CLI starts a local HTTP callback server. The compose override
publishes `${AGENTIC_OAUTH_PORT:-19999}:19999`, so a callback bound inside the
container is reachable from the host at:

```text
http://127.0.0.1:19999/
```

Prefer explicit IPv4 loopback (`127.0.0.1`) instead of `localhost`. This avoids
IPv6 localhost resolution problems seen in Claude Code bug #44844 and similar
callback handlers.

Example: `opencode auth login`.

### Neither flow

Some products authenticate only through a proprietary desktop IDE or extension.
Run those on the host and treat the container command as a stub.

Examples: Cursor desktop auth, Cline VS Code extension auth, Continue IDE auth.

## Tool matrix

| Tool | Flow | Persisted to | Known issues |
|---|---|---|---|
| `aider` | API key env vars | `cfg/agentic-shared/.env` | Set `OPENAI_API_KEY` or another provider key; no OAuth bridge flow. |
| `claude-code` | Device-code OAuth | `cfg/agentic-claude/.credentials.json` | Use `./dvl agent auth claude-code`; IPv4 callback guidance applies if a provider redirects locally. |
| `cline` | Host IDE-only | host VS Code/Cline profile | Container stub cannot complete extension auth. |
| `codex` | Web/device OAuth | `cfg/agentic-codex/` | `./dvl agent auth codex` launches `codex login`; provider behavior may vary. |
| `codewhale` | API key/env or upstream CLI | `cfg/agentic-codewhale/` | No bridge mapping yet; use documented upstream auth. |
| `continue` | Host IDE-only/API keys | host Continue profile or shared env | Container CLI does not replace IDE login. |
| `crush` | API key/env | `cfg/agentic-crush/` or shared env | No OAuth bridge mapping yet. |
| `cursor` | Host IDE-only | host Cursor profile | Cursor auth is proprietary desktop-only; use host Cursor. |
| `gh-copilot` | Device-code OAuth | `cfg/agentic-copilot/hosts.yml` | Requires Copilot-enabled GitHub account. |
| `goose` | API key/env or provider auth | `cfg/agentic-goose/` | Use provider env vars unless upstream CLI prints a bridgeable URL. |
| `hermes` | API key/env | `cfg/agentic-hermes/` or shared env | No OAuth bridge mapping yet. |
| `llm` | API key/env | `cfg/agentic-llm/` and shared env | Use `llm keys set` or env vars; no browser flow by default. |
| `opencode` | Callback OAuth | `cfg/agentic-opencode/auth.json` | Ensure callback binds/reaches `127.0.0.1:19999`. |
| `qwen-code` | Browser/device or API key | `cfg/agentic-qwen-code/` | Bridge not mapped yet; use upstream CLI instructions. |
| `reasonix` | API key/env | `cfg/agentic-reasonix/` or shared env | No OAuth bridge mapping yet. |

## Troubleshooting

- Tail logs with `cd devilbox && ./dvl agent logs`.
- Check the FIFO exists: `ls -l devilbox/.devilbox/oauth-fifo/url`. If missing,
  the host bridge and container startup hook create it idempotently.
- Check `BROWSER` inside the container:
  `./dvl agent exec 'printf "%s\n" "$BROWSER"'` should print
  `/usr/local/bin/dvl-open-host`.
- Check callback reachability with `devilbox/.tests/oauth/callback-reach.sh`.
- Keep `LOCAL_LISTEN_ADDR` compatible with loopback publishing and do not change
  the default `AGENTIC_OAUTH_PORT` of `19999` unless the CLI also changes ports.
- If a callback opens `localhost`, retry with `127.0.0.1`; this is the documented
  mitigation for Claude Code IPv6 localhost bug #44844.
- Unsupported tools return `no auth flow defined for tool X`; use env vars or
  host-only auth as described in the table.
