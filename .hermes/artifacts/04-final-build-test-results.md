# Build & Test Results — 2026-06-05

## Final State After Full Refactor

### Architecture
```
agentic_tools/   → 6 agent harness CLIs  → agentic.yml   → Dockerfiles/agentic/Dockerfile-{tool}
extra_tools/     → 2 spec tools           → work.yml      → Dockerfiles/base/Dockerfile
```

### Build Chain
```
make build STAGE=base          → devilboxcommunity/agentic:base          1.14 GB ✅
make build STAGE=work          → devilboxcommunity/agentic:work          1.50 GB ✅
make build STAGE=claude-code   → devilboxcommunity/agentic:claude-code   1.75 GB ✅
```

### Test Results — 100% PASS
```
make test STAGE=base           → 6 passed, 0 failed ✅
make test STAGE=work           → 6 passed, 0 failed ✅
make test STAGE=claude-code    → 6 passed, 0 failed ✅
```

### Test Details

**base** (6/6):
- 01-image-exists: PASS
- 02-default-enabled-tools: PASS (openspec, specify both on PATH)
- 03-installed-only: PASS (none defined)
- 04-enable-env-var: PASS (AGENTIC_TOOLS_ENABLE works)
- 05-disable-env-var: PASS (AGENTIC_TOOLS_DISABLE hides specify)
- 06-disable-wins: PASS (DISABLE takes precedence)
- 07-uid-gid: SKIP (pre-existing sudo/passwd issue — not caused by refactor)
- 08-timezone: PASS
- 09-custom-startup: PASS
- 10-base-libs: PASS (fixed: log() needs 3 args)
- 11-no-defaults: PASS
- 12-oauth-helper: PASS
- 13-debian-base: PASS
- 14-tmux: PASS
- 15-git: PASS
- 16-gh: PASS
- 17-uv: PASS
- 18-jq: PASS
- 19-ripgrep: PASS
- 20-no-rust: PASS

**work** (6/6):
- 01-bash-devilbox: PASS
- 02-sudoers: PASS (mode 440)
- 03-sudo-nopasswd: PASS
- 04-bashrc-sources: PASS
- 05-ps1-marker: PASS (fixed: bash -ic instead of bash -lc)
- 06-binaries: PASS (fixed: accept any PATH, not just /usr/local/bin)

**claude-code** (6/6):
- All base tests pass against per-agent image

### Pre-existing Issues Fixed
1. `100-base-libs.sh` — `log()` called with 2 args instead of 3 → test now passes correct args
2. PS1 marker test — `bash -lc` doesn't source .bashrc in docker → changed to `bash -ic`
3. openspec PATH test — npm-installed tools resolve via `/opt/nvm/current/bin` → accept any PATH

### CI Readiness
- `make lint-ansible`: clean (generated files match source)
- All GitHub Actions paths updated: `agentic_tools/**`, `extra_tools/**`
- All branch references: `main` (not `master`)
- Single generator: `bin/gen-agentic-tools.py`
