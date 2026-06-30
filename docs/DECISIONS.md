# Decisions (why it's built this way)

Short ADR-style notes on the non-obvious choices, so future-me doesn't relitigate
them.

## chezmoi for dotfile management
**Why:** Need one source of truth that handles *per-machine* differences
(personal vs work) and keeps secrets out of git. chezmoi templates configs from
profile data, integrates with 1Password for secret injection at apply-time, and
gives a clean `init --apply` on a fresh Mac. Plain symlinks (the previous
approach) and GNU stow can't template or branch by machine.
**Trade-off:** files use chezmoi's naming (`dot_`, `private_`, `.tmpl`); you edit
via `chezmoi edit` rather than the live file. Worth it.

## mise for runtimes (replacing nvm + brew node)
**Why:** Previously Node came from nvm *and* a shadowed brew `node@22`, with a
third pnpm hiding in nvm — ambiguous and slow. mise is one fast tool, reads
`.nvmrc`/`.tool-versions`/`mise.toml` per project, and manages more than Node.
**Trade-off:** another tool to learn, but it subsumes nvm/asdf. nvm (~1 GB) and
brew `node@22` removed after validating Node works under mise.

## Drop oh-my-zsh, keep Starship
**Why:** Once the prompt moved to Starship, OMZ only provided two plugins and a
git-alias set we didn't use (0 history hits). Replaced with brew
`zsh-autosuggestions` + `zsh-syntax-highlighting` — faster startup, fewer moving
parts. Curated git aliases added back in `aliases.zsh`.

## conda: lazy-load
**Why:** conda initialized on *every* shell but never auto-activated an env —
pure startup cost. Now a shell function loads it on first `conda` use. Still
available for notebooks; shells stay fast.

## Profiles instead of branches
**Why:** One `main` that works everywhere beats per-machine branches that drift.
A `profile` (personal/work) chosen at init drives identity, Brewfile selection,
and signing via templates.

## Split Brewfiles (core / personal / work)
**Why:** A work machine shouldn't install LaTeX/matplotlib/personal tooling, and
a personal machine shouldn't carry work-only tools. `core` is the shared
toolchain; the profile picks the rest.

## gitleaks pre-commit hook
**Why:** This repo must contain `op://` references and templates only. A scanner
makes "never commit a secret" enforced, not just intended. The hook lives in
`scripts/hooks/` (version-controlled) and is wired via `core.hooksPath`.

## XDG-clean home
**Why:** Dozens of per-host `.zcompdump*` files and tool state cluttered `$HOME`.
Compdump now lives in `~/.cache/zsh`; configs under `~/.config`.
