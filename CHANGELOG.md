# Changelog

All notable changes to macstrap are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project aims to follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.6.0] - 2026-07-01

### Added

- `macstrap cli`: an optional, project-specific CLI catalog
  ([`brew/cli.catalog`](brew/cli.catalog)) with an interactive grouped picker and
  group/name install (`macstrap cli backend,ai`, `macstrap cli supabase,stripe`,
  `macstrap cli --list`). Discovery, not default install — nothing here ships with
  the base bootstrap.
- Reproducible selections: chosen CLIs are recorded in `brew/selected.cli`, which
  the installer replays on a fresh machine (`install_selected_cli`). `macstrap
  report` now lists recorded CLIs and whether each is installed.
- `scripts/lib/catalog.sh`: shared catalog helpers used by both the installer and
  `macstrap cli`.
- `scripts/check-catalog.sh` (wired into CI): validates catalog rows and fails if
  an optional CLI duplicates a `Brewfile.core` package.
- ADR 0006: optional CLI catalog (discovery over default install).
- `macstrap demo [hero|apps|cli|doctor]`: scripted, non-mutating product
  walkthroughs (installs nothing). Backed by `demo/scripts/`.
- Demo tooling: VHS `.tape` files in `demo/tapes/`, `demo/record.sh` to
  regenerate the README GIFs, and `brew/Brewfile.dev` (vhs, shellcheck, shfmt)
  for contributors. New GIFs `demo-cli.gif` and `demo-doctor.gif`; `demo.gif`
  and `demo-apps.gif` re-recorded from the scripted walkthroughs.
- `docs/DEMOS.md` and `demo/README.md` documenting the demo workflow.

### Changed

- Unified catalog schema `key|formula|kind|categories|description` across
  `brew/apps.catalog` and `brew/cli.catalog`; `macstrap apps` now accepts a group
  or explicit list (`macstrap apps design`) for parity with `macstrap cli`.
- `starship` moved into `Brewfile.core` (the shipped zsh prompt runs `starship
  init`, so it is a core dependency, not optional).
- `macstrap doctor` human-readable output regrouped into System / Core / Runtimes
  / Security / Next for a scannable, screenshot-friendly report (the `--json`
  contract is unchanged); README leads with a hero walkthrough plus a "See it in
  action" table of per-topic demos.

### Fixed

- Selection parsing dropped the final comma-separated token (missing trailing
  newline before `read`); single-token selections like `macstrap apps design` now
  resolve correctly.
- The dry-run plan no longer prints a doubled `0` for an empty app count.

## [0.5.0] - 2026-06-30

### Added

- `docs/COLORS.md`: a documented, semantic Vesper color language applied
  consistently across Starship, fzf, and the terminal palette.
- Architecture Decision Records under `docs/adr/` (chezmoi, mise, profiles,
  1Password, split Brewfiles).

### Changed

- Semantic Starship colors: path leads (lavender), git context recedes (muted
  branch, dimmed status), and the prompt is the one pink accent. fzf themed to
  Vesper.
- Ghostty default is opaque with no blur for readability; translucency and blur
  are an opt-in "aesthetic mode".
- Demos re-recorded as a floating macOS window (traffic lights, rounded corners,
  soft backdrop) with the new colors.

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

[Unreleased]: https://github.com/XavierAgostino/macstrap/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/XavierAgostino/macstrap/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/XavierAgostino/macstrap/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/XavierAgostino/macstrap/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/XavierAgostino/macstrap/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/XavierAgostino/macstrap/releases/tag/v0.1.0
