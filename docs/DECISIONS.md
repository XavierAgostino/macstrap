# Decisions (why it is built this way)

Short, ADR-style notes on the non-obvious choices, so they do not get
relitigated later. Formal records are in [adr/](adr/).

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

## Optional CLI catalog (discovery, not default install)

**Why:** project-specific CLIs (cloud, database, deploy, Kubernetes) shouldn't
bloat every machine, but shouldn't be rediscovered from scratch either. So the
core stays lean and `brew/cli.catalog` holds an opt-in menu that `macstrap cli`
installs by group or name. Picks are recorded in `brew/selected.cli` and replayed
by the installer, so the CLI stack is reproducible config, not a one-off install.
**Trade-off:** the catalog is a curated list to maintain (formula names drift),
so it's kept small and CI-validated rather than exhaustive.

## Versioned JSON contracts as the engine/UI seam

**Why:** macstrap is a two-layer product — a boring, reliable shell engine and
a Go TUI over it. For the TUI to never drift from or reimplement the
engine, the scripts expose their state as versioned JSON (`macstrap.doctor/v1`,
`macstrap.catalog/v1`, `macstrap.plan/v1`, `macstrap.report/v1`,
`macstrap.security/v1`). The same contracts serve AI agents and CI. Output is
emitted without a `jq` dependency (a fresh Mac has no packages yet), the human
and JSON views render from one shared computation so they can't disagree, and a
CI job validates every contract on each push. Documented in
[JSON-CONTRACTS.md](JSON-CONTRACTS.md).
**Trade-off:** a schema is a promise — fields may be added within a version, but
removals bump it (`/v2`). Worth it: the TUI, agents, and tests all read one
stable interface instead of scraping human text.

## A single Go binary is the `macstrap` entrypoint (shell as fallback)

**Why:** with the TUI in Go and the engine in shell, having two competing
front ends would confuse everyone. So the Go binary *is* `macstrap`: no
arguments opens the TUI, and any subcommand (`macstrap doctor --json`,
`macstrap install --dry-run`, …) is delegated **verbatim** to the bash
entrypoint (`bin/macstrap`), which mirrors its exit code. The Go layer renders
or delegates; it never reimplements setup logic. `bin/macstrap` stays fully
functional as the fallback for anyone without the binary (and it's what CI and
the installer use directly).
**Trade-off:** subcommands pay one extra `bash` exec through the Go front end;
negligible next to Homebrew, and it buys one entrypoint with one behavior for
humans, scripts, and agents alike.

## Prebuilt binaries via GoReleaser (no Go toolchain on a fresh Mac)

**Why:** requiring `go build` on a brand-new Mac would defeat the point of a
one-line bootstrap. So tagged releases ship darwin `amd64`/`arm64` binaries with
a `checksums.txt`; `install.sh` downloads the right one and verifies it against
the checksum before installing to `~/.local/bin`. It runs **after** the shell
bootstrap and is non-fatal — a fresh Mac is fully set up by the engine whether
or not the binary lands, keeping the first install safe.
**Trade-off:** a build/release pipeline to maintain (`.goreleaser.yaml`,
`release.yml`), and the binary lags a tag; acceptable for a native TUI that
starts instantly and needs no runtime.

## Quiet-by-default install, with logs and `--verbose`

**Why:** a fresh install runs long, noisy commands (`brew bundle`, `mise
install`). Dumping every line makes real errors easy to miss and feels
unpolished; a fake percentage bar would be dishonest since Homebrew timing is
unpredictable. So the installer shows honest step-based progress (`[n/10]`
phases with `ok`/`skip`/`warn`/`fail`), routes noisy steps through a `gum`
spinner, and captures their output to a per-step log shown only on failure.
`--verbose` streams everything for debugging. Shared helpers live in
`scripts/lib/ui.sh` so the installer and CLIs speak one output language.
**Trade-off:** hiding output by default risks concealing a hang, so only
provably non-interactive steps are wrapped — Homebrew's installer and every
`chezmoi` step always stream, and non-TTY/CI runs stream too.

## gitleaks pre-commit hook

**Why:** the repo should contain `op://` references and templates only. A scanner
makes "never commit a secret" enforced, not just intended. The hook lives in
`scripts/hooks/` (version-controlled) and is wired through `core.hooksPath`.

## XDG-clean home

**Why:** per-host `.zcompdump*` files and tool state clutter `$HOME`. The
compdump now lives in `~/.cache/zsh`, and configs live under `~/.config`.
