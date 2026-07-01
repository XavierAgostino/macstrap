# Changelog

All notable changes to macstrap are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project aims to follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Expand `dev-doctor --fix` with more safe repairs.
- CI matrix across profiles (personal/work) and app modes, plus `shfmt`,
  `actionlint`, and `markdownlint`.
- `scripts/report.sh` ("what did macstrap change?") and a conservative
  `scripts/uninstall.sh` (dry-run and dotfiles-only).
- ADR files under `docs/adr/`.
- `scripts/security-check.sh` (gitleaks, signing, `op`/`gh` auth status).

## [0.1.0] - 2026-06-30

### Added
- Installer with modes: `minimal`, `default`, `interactive`, `headless`, `doctor`.
- `DRY_RUN=1` plan preview (no changes).
- Controlled failure reporting: required vs optional steps with an end-of-run
  warning summary, replacing broad `|| true`.
- Catalog-driven and interactive app selection (`brew/apps.catalog`, `gum`),
  plus explicit `APPS=a,b,c` lists.
- `dev-doctor --json` (machine-readable status) and `dev-doctor --fix`
  (safe repairs).
- One-line `install.sh` bootstrapper with confirmation and `NONINTERACTIVE=1`.
- `docs/AGENT-USAGE.md` for agent-safe operation.
- Foundations: chezmoi source with personal/work profiles, mise runtimes, split
  Brewfiles, 1Password-backed SSH commit signing, gitleaks pre-commit hook,
  macOS defaults script, CI (shellcheck + chezmoi render + Brewfile parse), and
  documentation.

[Unreleased]: https://github.com/XavierAgostino/macstrap/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/XavierAgostino/macstrap/releases/tag/v0.1.0
