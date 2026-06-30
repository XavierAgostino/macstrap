# AGENTS.md

Conventions for AI coding agents (Codex, Cursor, Claude Code, etc.) working in
my repositories. Tool-agnostic; a project's own AGENTS.md/CLAUDE.md overrides
this where they differ. Defer to company policy on a work machine.

## Working style
- Be concise and direct; lead with the answer, then the reasoning and
  trade-offs. No filler.
- Understand before changing. Prefer small, reversible steps; make a safety net
  before anything hard to undo.
- Verify by running/observing real behavior. Report failures honestly with
  output; don't claim done until verified.
- Solve the problem asked at the right altitude — no speculative abstraction.

## Code
- Match the surrounding style, naming, and patterns. Clear, typed, well-named
  code over cleverness.
- Justify new dependencies or patterns; handle errors and edge cases explicitly.

## Git
- Branch before committing on the default branch; commit/push only when asked.
- Small, logically-scoped commits with clear imperative messages explaining the
  *why*.
- No AI/co-author attribution on commits or PRs.

## Testing & docs
- Test changes before calling them done; add/update tests when behavior changes.
- Document the *why*; keep READMEs current.

## Security
- Never hardcode or commit secrets — use the environment's secret manager and
  inject at runtime. `.env` holds references/placeholders only.
- Least privilege; scoped/restricted credentials.
