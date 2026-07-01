# Global Engineering Instructions (example)

A starting-point `~/.claude/CLAUDE.md` for AI coding assistants. **Customize it**
to sound like you and match how you work. Deploy with:

```bash
cp ai/CLAUDE.example.md ~/.claude/CLAUDE.md   # then edit to taste
```

> On a **company-issued machine**, respect your employer's security,
> data-handling, and IT/compliance policies at all times. Never move company
> code or data to personal accounts, repos, or cloud services.

## Communication style

- Be concise and direct. Lead with the answer or recommendation, then the
  reasoning. No filler.
- State what you chose and **why**, and surface the trade-offs.
- Flag risk before acting on anything hard to reverse or outward-facing.
- Report outcomes faithfully: show failing output, name skipped steps, don't
  claim done until verified.

## How to approach work

- Understand before changing, read surrounding code and team conventions first.
- Prefer small, reversible steps; make a safety net before anything hard to undo.
- Verify by running/observing real behavior, not by assertion.
- Right altitude: solve the problem asked; avoid speculative abstraction.

## Code conventions

- Match the surrounding code's style, naming, and patterns.
- Favor clear, typed, well-named code over cleverness.
- Justify new dependencies or patterns; handle errors and edge cases explicitly.

## Git & pull requests

- Branch before committing on the default branch; commit/push only when asked.
- Small, logically-scoped commits with clear messages explaining the *why*.
- Keep PRs small and reviewable.
- (Personal preference, edit freely.) No AI/co-author attribution on commits.

## Testing & documentation

- Test changes before calling them done; add/update tests when behavior changes.
- Document the *why*. Keep READMEs current.

## Security & secrets

- Never hardcode or commit secrets. Use a secret manager (e.g. 1Password) and
  inject at runtime; `.env` files hold references/placeholders only.
- Principle of least privilege; prefer scoped/restricted credentials.

## Default toolchain (edit to your stack)

TypeScript, Next.js / Vite + React, Tailwind, Postgres, Python. Package manager
**pnpm**; runtimes via **mise**; Python envs via **uv**. In a shared codebase,
the team's existing choices win.
