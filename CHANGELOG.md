# Changelog

## [Wave 9] — CI/CD canonical pattern alignment

Replaced 3 ad-hoc GitHub Actions workflows (build-base.yml, build-work.yml,
lint.yml) with the canonical Devilbox community pattern ported from
docker-php-fpm and trimmed from 5 stages to 2 stages (base→work):

- `.github/workflows/action.yml` — main orchestrator (6-phase pipeline:
  params → configure → build/test base → build/test work → push → manifest)
- `.github/workflows/action-manual.yml` — workflow_dispatch with stage/version/arch inputs
- `.github/workflows/action-schedule_tags.yml` — nightly tag builds (cron 18:00 Sun/Tue/Thu)
- `.github/workflows/action-schedule_master.yml` — nightly master builds (cron 18:00 Mon/Wed/Fri)
- `.github/workflows/params{,-manual,-nightly_tags,-nightly_master}.yml` — matrix providers
- `.github/workflows/release-drafter.yml` — drafts release notes on push to master
- `.github/workflows/linting.yml` — PR lint (Makefile-driven)
- `.github/workflows/generator.yml` — verifies committed Dockerfiles match generator output
- `.github/workflows/repository.yml` — label sync via micnncim/action-label-syncer@v1

All build/test/push/manifest logic delegated to
`devilbox-community/github-actions/.github/workflows/docker-multistage-*.yml@master`
reusable workflows (matches docker-php-fpm + docker-nginx-stable convention).

Required repository secrets:
- DOCKERHUB_USERNAME, DOCKERHUB_PASSWORD (for image push on master/tag/release-*)
- GITHUB_TOKEN (auto-provided, used by release-drafter + label syncer)

New .github metadata:
- release-drafter.yml (config), labels.yml, dependabot.yml, FUNDING.yml
- ISSUE_TEMPLATE/{bug_report,feature_request,config}.yml

## [Wave 8] — 2026-06-01

- Added 4 new tools (openclaw, pi-coding-agent, gemini, multica CLI).
- Promoted 4 stubs to real installers (cursor, codewhale, reasonix, hermes).
- Rewrote 6 tools to native installers (claude-code, opencode, codex, continue, qwen-code, crush) with no npm fallback.
- Added `AGENTIC_TOOLS_ENABLE/_DISABLE` runtime toggle and `_defaults.yml` as source of truth.
- Added `/opt/agentic-tools/_entrypoint.d/` to bypass configuration mount-shadowing.
- 11 tools enabled by default: claude-code, opencode, codex, cursor, codewhale, reasonix, hermes, openclaw, pi-coding-agent, gh-copilot, gemini.
- 8 opt-in tools: aider, goose, cline, continue, qwen-code, llm, crush, multica.
- Makefile aligned with `docker-php-fpm` style: bootstrap of external `Makefile.docker`/`Makefile.lint`, added `VERSION` / `STAGE` / `ARCH` / `TAG` args, canonical `build` / `rebuild` / `push` / `tag` / `save` / `load` / `manifest-create` / `manifest-push` / `test` targets, and `check-version-is-set` / `check-stage-is-set` / `check-current-image-exists` / `check-parent-image-exists` guards. Old `build-base` / `build-work` kept as deprecated aliases (one release cycle) that forward to `build STAGE=...`. CI workflows updated to the new syntax.

## [1.0.0] - 2026-06-01

### Added

- Initial release of the Devilbox agentic developer environment.
- 15 bundled AI coding CLI tools:
  - aider, claude-code, cline, codewhale, codex, continue, crush, cursor, gh-copilot, goose, hermes, llm, opencode, qwen-code, reasonix.
- Ansible-generated Dockerfiles for base and work images.
- Replaced Nodesource apt nodejs with nvm v0.40.4 + Node LTS managed at /opt/nvm.
- Added bun runtime at /usr/local/bin/bun.
- Devilbox integration:
  - Compose override for opt-in `agentic` service.
  - Persistent host-to-container directory mapping under `cfg/agentic-*`.
  - New `dvl agent` subcommands for service management.
- Browser OAuth bridge for host-to-container authentication flows (FIFO-based).
- Reference plan: `.sisyphus/plans/docker-agentic.md`.
