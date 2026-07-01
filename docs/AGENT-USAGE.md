# Agent-safe usage

Scriptable, non-interactive guidance for AI agents and CI. Use the `macstrap`
CLI (`macstrap install --dry-run`, `macstrap doctor --json`) or env vars
directly — env vars are the low-level interface.

```bash
PROFILE=work APPS=cursor,orbstack,tableplus DRY_RUN=1 bash scripts/bootstrap.sh
```

Env vars: `MODE`, `PROFILE`, `APPS`, `DRY_RUN`. Full list in
[README](../README.md) (Manual setup). Structured output:
[`JSON-CONTRACTS.md`](JSON-CONTRACTS.md).

## Safe commands

```bash
# Preview only, no changes:
DRY_RUN=1 bash scripts/bootstrap.sh

# Minimal / headless setup, no GUI apps (safe for CI and remote Macs):
MODE=headless bash scripts/bootstrap.sh
APPS=0 PROFILE=work bash scripts/bootstrap.sh

# Explicit app set, no TUI required:
APPS=cursor,orbstack,tableplus bash scripts/bootstrap.sh

# Machine-readable health status:
bash scripts/dev-doctor.sh --json

# Safe, non-destructive repairs, then a report:
bash scripts/dev-doctor.sh --fix
```

## Guardrails (do not do automatically)

- Do **not** run `scripts/macos-defaults.sh` without explicit user confirmation.
- Do **not** install GUI apps in headless or CI contexts. Use `MODE=headless` or
  `APPS=0`.
- Do **not** modify SSH config, signing keys, or DNS automatically.
- Do **not** commit when the gitleaks pre-commit hook fails.
- Prefer `DRY_RUN=1` first, then apply.

## Status contract

`macstrap doctor --json` emits `macstrap.doctor/v1` — see
[JSON-CONTRACTS.md](JSON-CONTRACTS.md). Treat `missing`, `locked`, `warning`,
and `off` as actionable; `ok` is healthy.

## Required vs optional steps

**Required** (Homebrew, clone, chezmoi init/apply, core packages) abort on failure.
**Optional** (GUI apps, profile packages, runtimes, dev-doctor) collect warnings
in the final summary — a run never fails silently.
