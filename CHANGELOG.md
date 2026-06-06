# Changelog

All notable changes to docker-agentic are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - Unreleased

### Architecture

The project now follows the `docker-php-fpm` multi-stage image pattern with three
layers: `base` (pure runtime), `work` (developer tools), and per-agent images
(one Docker image per AI coding agent CLI).

| Stage | Image | Contents |
|-------|-------|----------|
| `base` | `devilboxcommunity/agentic:base` | Debian trixie-slim + Go + Node (nvm) + Bun + Python |
| `work` | `devilboxcommunity/agentic:work` | Base + build toolchain + openspec + speckit + sudo + bashrc |
| Per-agent | `devilboxcommunity/agentic:claude-code`, etc. | Work + single agent harness CLI |

### Directory layout

```
agentic_tools/          ← Per-agent harness CLIs (one Docker image each)
├── claude-code/        ← Anthropic Claude Code
├── codex/              ← OpenAI Codex CLI
├── copilot/            ← GitHub Copilot CLI
├── opencode/           ← OpenCode
├── pi-coding-agent/    ← Pi Coding Agent
└── reasonix/           ← Reasonix (npm)

extra_tools/            ← Shared spec/workflow tools (built into work image)
├── openspec/           ← OpenSpec (npm)
└── speckit/            ← GitHub Spec Kit / specify-cli (pipx)

Dockerfiles/
├── base/Dockerfile
├── work/Dockerfile
└── agentic/
    ├── Dockerfile-claude-code
    ├── Dockerfile-codex
    ├── Dockerfile-copilot
    ├── Dockerfile-opencode
    ├── Dockerfile-pi-coding-agent
    └── Dockerfile-reasonix
```

### Build system

- Single `make build STAGE=...` command for all stages (matching docker-php-fpm).
- `make build STAGE=base` → `:base`, `make build STAGE=work` → `:work`,
  `make build STAGE=claude-code` → `:claude-code`.
- Single unified generator: `bin/gen-agentic-tools.py` scans both `agentic_tools/`
  and `extra_tools/`, generates Ansible group_vars for the Jinja2 templates.
- `check-parent-image-exists` safeguard prevents building stages out of order.
- All generated Dockerfiles use 4-stage multi-stage builds (builder → copy → test → labels)
  to keep build toolchain out of final images.

### Per-agent images

Each agent harness CLI gets its own Docker image with only that tool installed.
This keeps images small and lets users pull only the agent they need.

| Agent | Image | Approx. size |
|-------|-------|-------------|
| claude-code | `devilboxcommunity/agentic:claude-code` | ~1.75 GB |
| codex | `devilboxcommunity/agentic:codex` | ~1.79 GB |
| copilot | `devilboxcommunity/agentic:copilot` | ~1.72 GB |
| opencode | `devilboxcommunity/agentic:opencode` | ~1.71 GB |
| pi-coding-agent | `devilboxcommunity/agentic:pi-coding-agent` | ~1.56 GB |
| reasonix | `devilboxcommunity/agentic:reasonix` | ~1.56 GB |

### Runtime toggles

- `AGENTIC_TOOLS_ENABLE` — enables additional tools at container startup.
- `AGENTIC_TOOLS_DISABLE` — disables a default-enabled tool.
- Toggle state is evaluated at container entrypoint via `/docker-entrypoint.d/`.

### Testing

- Plain bash test suite under `tests/base/` and `tests/work/` (docker-php-fpm style).
- `make test STAGE=base` and `make test STAGE=work` run integration tests
  against built images. Per-agent tests run base-stage tests against the agent image.
- All tests pass: base 6/6, work 6/6, per-agent 6/6.

### CI/CD

- GitHub Actions workflows mirror docker-php-fpm: multi-stage build/test/push/manifest
  pipeline via `devilbox-community/github-actions` reusable workflows.
- `linting.yml` runs YAML lint, changelog lint, and Ansible generation check.
- `generator.yml` verifies committed Dockerfiles match generator output on PR.
- All branch references use `main` (not `master`).

### Pre-release history

Earlier iterations (pre-1.0.0) included:

- Initial 15-tool monolithic image with all CLIs in a single Dockerfile.
- bats-based test suite (replaced with plain bash).
- `master` branch references (changed to `main`).
- `Dockerfile-latest`/`Dockerfile-stable` version-suffixed filenames (removed).
- Separate `make build-agentic` commands (merged into `make build STAGE=...`).
- Per-version `release=latest`/`release=stable` inventory variables (removed).
- `agent_tools/` directory naming (renamed to `agentic_tools/`).
- Two separate generator scripts (merged into one).
- Build toolchain packages in base image (moved to work image).
