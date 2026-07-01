# Agent-safe usage

Guidance for AI agents and automation driving macstrap. Everything here is
scriptable and non-interactive, and every action is either a preview or a
declarative apply.

The `macstrap` CLI wraps these (`macstrap install --dry-run`,
`macstrap doctor --json`, `macstrap install --headless`). Agents may use either
the CLI or the env vars below; the env vars are the low-level interface.

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

- Do **not** run `scripts/macos-defaults.sh` without explicit user confirmation;
  it changes system preferences.
- Do **not** install GUI apps in headless or CI contexts. Use `MODE=headless` or
  `APPS=0`.
- Do **not** modify SSH config, signing keys, or DNS automatically.
- Do **not** commit when the gitleaks pre-commit hook fails.
- Prefer `DRY_RUN=1` first, then apply.

## Status contract

`dev-doctor.sh --json` returns a flat status object:

```json
{
  "homebrew": "ok",
  "chezmoi": "ok",
  "mise": "ok",
  "node": "ok",
  "git_signing": "off",
  "onepassword": "locked",
  "gitleaks": "ok"
}
```

Treat `missing`, `locked`, `warning`, and `off` as actionable; `ok` is healthy.

## Required vs optional steps

The installer separates **required** steps (Homebrew, clone, chezmoi init/apply,
core packages) from **optional** ones (GUI apps, profile packages, runtimes,
dev-doctor). A required failure aborts; optional failures are collected and
printed as warnings in the final summary, so a run never fails silently.
