# Decisions (why it is built this way)

Short, ADR-style notes on the non-obvious choices, so they do not get
relitigated later.

## chezmoi for dotfile management
**Why:** one source of truth that handles per-machine differences (personal vs
work) and keeps secrets out of git. chezmoi templates configs from profile data,
integrates with 1Password for secret injection at apply time, and gives a clean
`init --apply` on a fresh Mac. Plain symlinks and GNU stow cannot template or
branch by machine.
**Trade-off:** files use chezmoi's naming (`dot_`, `private_`, `.tmpl`), and you
edit through `chezmoi edit` rather than the live file. Worth it.

## mise for runtimes (replacing nvm and pyenv)
**Why:** one fast tool that reads `.nvmrc`, `.tool-versions`, and `mise.toml` per
project, and manages more than Node. It removes the common ambiguity of Node
resolving from several places at once (nvm, Homebrew, a global install).
**Trade-off:** another tool to learn, but it subsumes nvm and asdf.

## Drop oh-my-zsh, keep Starship
**Why:** once the prompt moves to Starship, oh-my-zsh mostly adds startup cost.
Lightweight Homebrew plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`)
cover the rest, and a curated set of git aliases lives in `aliases.zsh`.

## conda: lazy-load
**Why:** eagerly initializing conda in every shell is pure startup cost when no
environment is active. A shell function loads it on first use, so conda stays
available for notebooks while shells stay fast.

## Profiles instead of branches
**Why:** one `main` that works everywhere beats per-machine branches that drift.
A profile (`personal` or `work`) chosen at init drives identity, Brewfile
selection, and signing through templates. (You also cannot have a private branch
in a public repo.)

## Split Brewfiles (core / apps / personal / work)
**Why:** a work machine should not install personal-only tooling, and a personal
machine should not carry work-only tools. `core` is the shared toolchain, `apps`
is the GUI starter set, and the profile picks the rest.

## gitleaks pre-commit hook
**Why:** the repo should contain `op://` references and templates only. A scanner
makes "never commit a secret" enforced, not just intended. The hook lives in
`scripts/hooks/` (version-controlled) and is wired through `core.hooksPath`.

## XDG-clean home
**Why:** per-host `.zcompdump*` files and tool state clutter `$HOME`. The
compdump now lives in `~/.cache/zsh`, and configs live under `~/.config`.
