# Engineering Practices (portable)

How I work as an engineer, written to be machine- and project-agnostic. Both my
personal and work AI assistant configs reference this layer; project- or
company-specific details are layered on top elsewhere, never here.

This file contains **no secrets, no company specifics, and no personal vault
references**: it is safe to share.

## Communication style

- Be concise and direct. Lead with the answer or the recommendation, then the
  reasoning. Skip filler and flattery.
- When you make a choice, say what you chose and **why**, and surface the
  trade-offs you weighed — don't just present a menu of options.
- Flag risk honestly: if something is hard to reverse, outward-facing, or
  uncertain, call it out before doing it.
- Report outcomes faithfully. If tests fail, say so with the output. If a step
  was skipped, say that. Don't claim done until it's verified.

## How to approach work

- Understand before changing. Read the surrounding code and conventions first.
- Prefer small, reversible steps. Make a safety net (branch, backup) before
  anything hard to undo.
- Verify your work — run it, test it, observe the real behavior — rather than
  asserting it works.
- Keep changes at the right altitude: solve the problem asked, don't
  over-engineer or introduce speculative abstraction.

## Code conventions

- Match the surrounding code's style, naming, and patterns. Consistency beats
  personal preference inside an existing codebase.
- Favor clear, typed, well-named code over cleverness. Name things for what they
  do.
- Don't introduce new dependencies, frameworks, or patterns casually — justify
  them.
- Handle errors and edge cases explicitly; don't swallow failures.

## Git & pull requests

- Branch before committing on the default branch. Keep commits small and
  logically scoped, with clear, imperative messages explaining the *why*.
- Commit and push only when asked.
- **Do not add AI/co-author attribution** (no `Co-Authored-By`, no "Generated
  with" trailers) to commits or PRs.
- Keep PRs small and reviewable; write a description that explains intent and
  trade-offs, not just a diff summary.

## Testing & verification

- Test changes before calling them done. Add or update tests when changing
  behavior.
- When something is broken, show the failing output; don't paper over it.

## Documentation

- Document the *why*, not just the *what*. Keep READMEs and setup docs current
  as the code changes.
- Prefer self-explanatory code and a short rationale over heavy comments.

## Security & secrets

- Never hardcode or commit secrets. Use the environment's designated secret
  manager and inject at runtime.
- `.env` files hold references/placeholders, never real values; the only
  committed env file uses placeholders.
- Principle of least privilege; prefer scoped/restricted credentials.

## Default toolchain (adapt to the team's actual stack)

TypeScript, Next.js (App Router) / Vite + React, Tailwind, shadcn/ui, Supabase /
Postgres, Vercel, Python. Package manager **pnpm**; monorepos with Turborepo;
runtimes via **mise**; Python envs via **uv**. These are personal defaults — in
a shared codebase, the team's existing choices win.
