# JSON contracts

Stable, machine-readable output from the shell engine. The Go TUI, AI agents,
and CI all read these; the shell scripts are the single source of truth and the
TUI never reimplements their logic.

Every contract carries a versioned `schema` string. Fields may be **added**
within a version; **removals or meaning changes** bump the version (for example
`macstrap.doctor/v2`). The `JSON contracts` CI job validates each command below
against its schema on every push.

The scripts emit these without needing `jq` at runtime, so they work on a fresh
Mac before any packages are installed. Consumers may parse with `jq` or any JSON
library.

## `macstrap doctor --json` — `macstrap.doctor/v1`

Machine health. `overall` and each check's `level` are the normalized traffic
light (`ok` | `warn` | `error`); `status` is the raw per-check state.

```bash
macstrap doctor --json      # or: bash scripts/dev-doctor.sh --json
```

```json
{
  "schema": "macstrap.doctor/v1",
  "overall": "warn",
  "summary": { "ok": 6, "warn": 1, "error": 1 },
  "checks": [
    {
      "key": "homebrew",
      "group": "Core",
      "label": "Homebrew",
      "status": "ok",
      "level": "ok",
      "hint": ""
    },
    {
      "key": "git_signing",
      "group": "Security",
      "label": "Git signing",
      "status": "off",
      "level": "warn",
      "hint": "Enable commit signing — see docs/work-separation.md"
    }
  ]
}
```

| Field | Meaning |
| --- | --- |
| `overall` | Worst level across all checks: `ok` \| `warn` \| `error`. |
| `summary` | Counts per level. |
| `checks[].key` | Stable identifier (`homebrew`, `chezmoi`, `mise`, `github`, `node`, `git_signing`, `onepassword`, `gitleaks`). |
| `checks[].group` | Display grouping: `Core` \| `Runtimes` \| `Security`. |
| `checks[].label` | Human label for the row. |
| `checks[].status` | Raw state (`ok`, `missing`, `warning`, `locked`, `off`). |
| `checks[].level` | Normalized `ok` \| `warn` \| `error`. |
| `checks[].hint` | Suggested next step when not `ok`; empty otherwise. |

## `macstrap apps --list --json` / `macstrap cli --list --json` — `macstrap.catalog/v1`

The full app or CLI catalog plus state. `catalog` is `"apps"` or `"cli"`. Apps
carry `defaults` (the keys installed by default); CLIs carry `selected` (keys
recorded in `brew/selected.cli`).

```bash
macstrap cli --list --json
macstrap apps --list --json
```

```json
{
  "schema": "macstrap.catalog/v1",
  "catalog": "cli",
  "categories": ["ai", "backend", "cloud", "database", "kubernetes"],
  "selected": ["supabase", "stripe"],
  "items": [
    {
      "key": "supabase",
      "formula": "supabase/tap/supabase",
      "kind": "brew",
      "categories": ["backend", "database"],
      "description": "Local Supabase, migrations, Edge Functions, types"
    }
  ]
}
```

| Field | Meaning |
| --- | --- |
| `catalog` | `"apps"` or `"cli"`. |
| `categories` | Every category name (excluding `default`). |
| `defaults` | Apps only: keys installed by default. |
| `selected` | CLIs only: keys recorded for replay. |
| `items[].key` | Stable identifier used by selections. |
| `items[].formula` | Homebrew formula/cask name. |
| `items[].kind` | `brew` or `cask`. |
| `items[].categories` | Categories this item belongs to. |
| `items[].description` | One-line description. |

## `macstrap apps <sel> --json` / `macstrap cli <sel> --json` — `macstrap.plan/v1`

A selection (categories and/or keys) resolved to a flat, de-duplicated key list.
Non-mutating — it installs nothing, so it is safe for previews and dry runs.

```bash
macstrap cli backend,ai --json
macstrap apps cursor,ghostty --json
```

```json
{
  "schema": "macstrap.plan/v1",
  "catalog": "cli",
  "keys": ["supabase", "stripe", "redis", "grpcurl", "ollama", "llm", "aider"]
}
```

## `macstrap report --json` — `macstrap.report/v1`

What macstrap manages on this machine.

```bash
macstrap report --json
```

```json
{
  "schema": "macstrap.report/v1",
  "profile": "personal",
  "homebrew": { "core": 30, "apps": 5 },
  "dotfiles_count": 22,
  "cli": [
    { "key": "supabase", "status": "installed" },
    { "key": "stripe", "status": "recorded" }
  ]
}
```

| Field | Meaning |
| --- | --- |
| `profile` | Active chezmoi profile (`personal` \| `work` \| `unknown`). |
| `homebrew.core` | Package count in `Brewfile.core`. |
| `homebrew.apps` | Casks in the last generated apps Brewfile (`0` if none). |
| `dotfiles_count` | Number of chezmoi-managed files. |
| `cli[].status` | `installed` (present via brew) or `recorded` (selected, not yet installed). |

## `macstrap security --json` — `macstrap.security/v1`

Security posture. `overall` is `ok` only when every check is `ok`.

```bash
macstrap security --json
```

```json
{
  "schema": "macstrap.security/v1",
  "overall": "warn",
  "checks": [
    { "key": "secrets", "label": "Secrets (gitleaks)", "level": "ok", "detail": "clean" },
    { "key": "commit_signing", "label": "Commit signing", "level": "warn", "detail": "off" }
  ]
}
```

| Field | Meaning |
| --- | --- |
| `overall` | `ok` \| `warn`. |
| `checks[].key` | `secrets`, `commit_signing`, `precommit_hook`, `onepassword`, `github_auth`. |
| `checks[].level` | `ok` \| `warn`. |
| `checks[].detail` | Short human explanation of the state. |
