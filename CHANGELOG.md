# Changelog

All notable changes to macstrap are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project aims to follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Architecture Decision Records under `docs/adr/` (chezmoi, mise, profiles,
  1Password, split Brewfiles).

## [0.4.0] - 2026-06-30

### Added

- CI lint jobs: `shfmt` (shell formatting), `actionlint` (workflows), and
  `markdownlint` (docs), alongside shellcheck and the render matrix.
- `dev-doctor --fix` now also relinks the `macstrap` CLI and reconciles core
  Homebrew packages.
- `.markdownlint.json` config.

### Changed

- All shell scripts formatted with `shfmt` (`-i 2 -ci`) for consistency.

## [0.3.0] - 2026-06-30

### Added

- `bin/macstrap` CLI: `install`, `apps`, `doctor`, `diff`, `apply`, `update`,
  `report`, `security`, `uninstall`, `version`, `help`. Friendly flags
  (`--minimal`, `--headless`, `--work`, `--personal`, `--apps`, `--no-apps`,
  `--dry-run`) are the primary UX; env vars remain the low-level interface.
- The bootstrap links the CLI to `~/.local/bin/macstrap`.

### Changed

- README leads with the `macstrap` CLI; raw env-var usage moved to an
  "Advanced" section. Demos re-recorded to use the CLI.

## [0.2.0] - 2026-06-30

### Added

- `scripts/report.sh`: show what macstrap manages on this machine (read-only).
- `scripts/uninstall.sh`: conservative back-out of managed dotfiles, dry-run by
  default, with backups on `--apply`. Never touches Homebrew, 1Password, or data.
- `scripts/security-check.sh`: gitleaks, commit signing, hook, and `op`/`gh`
  posture at a glance.
- Interactive app-picker demo GIF (Vesper theme).
- CI matrix across `personal` and `work` profiles; `install.sh` added to shellcheck.

### Changed

- Resolve the app selection exactly once, so the interactive picker renders
  correctly during planning and the same choice drives the install.

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

[Unreleased]: https://github.com/XavierAgostino/macstrap/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/XavierAgostino/macstrap/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/XavierAgostino/macstrap/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/XavierAgostino/macstrap/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/XavierAgostino/macstrap/releases/tag/v0.1.0
