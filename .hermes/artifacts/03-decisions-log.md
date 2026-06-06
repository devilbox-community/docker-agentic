# Decisions Log — docker-agentic Alignment with docker-php-fpm

## 2026-06-05

### Decision 1: Split agentic_tools into agent_tools (per-agent) and agentic_tools (shared)
- **Why**: docker-php-fpm separates php_modules (extensions in mods stage) from php_tools (CLI tools in work stage)
- **Applied**: agentic_tools = openspec + speckit (shared, in base); agent_tools = claude-code, codex, copilot, opencode, pi-coding-agent, reasonix (per-agent images)
- **Status**: ✅ Complete

### Decision 2: Use unified `make build STAGE=...` instead of `make build-agentic`
- **Why**: docker-php-fpm uses `make build STAGE=base|mods|prod|slim|work` — no special-cased targets
- **Applied**: `check-stage-is-set` accepts base, work, and all agent tool names
- **Status**: ✅ Complete

### Decision 3: Per-agent Docker tags should be plain tool names (no version prefix)
- **Why**: User requested `devilboxcommunity/agentic:claude-code` not `:latest-claude-code`
- **Applied**: `DOCKER_TAG` computed via `$(IS_AGENTIC)` conditional in Makefile
- **Status**: ✅ Complete

### Decision 4: Remove build toolchain from base image
- **Why**: docker-php-fpm's base is minimal; build tools go in builder stages
- **Applied**: Removed build-essential, gcc, g++, cmake, libffi-dev, libssl-dev, python3-dev, pkg-config, make from Dockerfile-base.j2
- **Status**: ✅ Applied, rebuilding to verify

### Decision 5: Add npm/pip cache cleanup to macros
- **Why**: Reduce layer size; docker-php-fpm uses builder→COPY pattern which avoids cache entirely
- **Applied**: Added `npm cache clean --force` and `pip cache purge` to both macro variants
- **Status**: ✅ Complete

### Decision 6: Fix branch references from master to main
- **Why**: Repository uses `main` as default branch
- **Applied**: Updated all .github/workflows/*.yml files (branch triggers, DEFAULT_BRANCH, refs/heads)
- **Status**: ✅ Complete

### Decision 7: Keep external `@master` workflow references unchanged
- **Why**: `devilbox-community/github-actions@master` points to the external repo's branch, not ours
- **Applied**: No changes to `uses: ...@master` lines
- **Status**: ✅ Correct — external repo uses master

### Decision 8: Per-agent images FROM work (not base)
- **Why**: Users need the full developer environment (sudo, bash completions)
- **Applied**: Dockerfile-agentic.j2 FROMs work instead of base
- **Status**: ✅ Complete

### Decision 9: speckit does NOT need python3-dev as build_dep
- **Why**: specify-cli ships pre-built wheels on PyPI; pipx installs without compilation
- **Applied**: speckit/install.yml build_dep: []
- **Status**: ✅ Complete

### Pending Decisions

### Pending 1: Should Go be moved out of the base image?
- docker-php-fpm doesn't include Go in the base
- Go is 150MB and only needed by Go-based tools
- Could be a separate image or installed per-tool as build_dep
- **Risk**: Some agent tools may need go at runtime

### Pending 2: Should Bun be moved out of the base image?
- Bun is 100MB
- Only needed by tools that use Bun
- Could be installed as build_dep per-tool

### Pending 3: Should the base image use a builder stage for agentic_tools?
- Currently installs openspec/speckit inline
- Adding a builder stage would keep npm/pip caches out of final image
- But for 2 small tools (~7MB total), overhead may not justify complexity
