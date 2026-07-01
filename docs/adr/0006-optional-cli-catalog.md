# 6. Optional CLI catalog (discovery over default install)

Date: 2026-07-01

Status: Accepted

## Context

Developers need project-specific CLIs — cloud (`awscli`), deploy (`vercel-cli`,
`flyctl`), database (`supabase`, `libpq`), Kubernetes (`kubectl`, `helm`),
infrastructure (`opentofu`), and so on. Installing all of them on every machine
would bloat the base setup, slow bootstrap, and vet tools most machines never use.
But leaving them out entirely means every developer re-derives how to install each
one. `Brewfile.core` deliberately stays lean (see
[ADR 0005](0005-split-brewfiles.md)); these tools do not belong there.

## Decision

Add an optional CLI catalog, `brew/cli.catalog`, using the same
`key|formula|kind|categories|description` schema as `brew/apps.catalog`. It is
**discovery, not default install**: nothing in it ships with the base bootstrap.
`macstrap cli` installs from it by interactive picker, by group, or by name, and
records the selection in `brew/selected.cli`. The installer replays that file on a
fresh machine, so the CLI stack is reproducible config rather than a one-off
`brew install`. Parsing/selection logic is shared with the app picker via
`scripts/lib/catalog.sh`, and CI (`scripts/check-catalog.sh`) forbids a catalog
entry from duplicating a `Brewfile.core` package.

## Consequences

- The base machine stays small; optional tooling is opt-in and self-documenting
  (`macstrap cli --list`).
- Selections are reproducible across machines through `brew/selected.cli`.
- `macstrap doctor` intentionally does **not** check optional CLIs — a missing
  optional tool is not a broken machine; `macstrap report` inventories them.
- The catalog is curated, not exhaustive: every row is a maintenance liability
  (formula renames), so tools are added when a project needs them, not
  speculatively.
