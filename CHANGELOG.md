# Changelog

## [1.0.0] - 2026-06-01

### Added

- Initial release of the Devilbox agentic developer environment.
- 15 bundled AI coding CLI tools:
  - aider, claude-code, cline, codewhale, codex, continue, crush, cursor, gh-copilot, goose, hermes, llm, opencode, qwen-code, reasonix.
- Ansible-generated Dockerfiles for base and work images.
- Devilbox integration:
  - Compose override for opt-in `agentic` service.
  - Persistent host-to-container directory mapping under `cfg/agentic-*`.
  - New `dvl agent` subcommands for service management.
- Browser OAuth bridge for host-to-container authentication flows (FIFO-based).
- Reference plan: `.sisyphus/plans/docker-agentic.md`.
