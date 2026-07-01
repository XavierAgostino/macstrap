# 3. Profiles, not branches, for machine variation

Date: 2026-06-30

Status: Accepted

## Context

A personal machine and a work machine need different git identities, package
sets, and commit-signing behavior. One tempting model is a long-lived branch per
machine. That model diverges quickly, forces constant cherry-picking of shared
changes, and, critically, cannot provide privacy: every branch of a public repo
is public.

## Decision

Keep a single `main` and vary behavior with a **profile** (`personal` or `work`)
chosen at `chezmoi init`. The profile drives git identity, which Brewfiles
install, and signing, all through templates. Machine-specific values live in
local chezmoi config, never in git.

## Consequences

- One branch works everywhere; shared changes never need porting.
- Truly private material stays out of the repo entirely (local config, or a
  separate private repo), which is the only real way to keep it private.
- Adding a new machine type is a new profile value, not a new branch.
