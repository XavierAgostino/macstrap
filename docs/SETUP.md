# Setup (fresh Mac)

A detailed walkthrough of standing up a new machine from this repo. For the short
version, see the README.

## Prerequisites

- Apple Silicon Mac, current macOS.
- Internet access. Sign in to the App Store / Apple ID as desired.

> [!NOTE]
> On a work machine, complete any IT/MDM enrollment first, and confirm you have
> admin rights (or know what is restricted) before installing.

## 1. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Homebrew also installs the Xcode Command Line Tools, which provide git.

## 2. Clone and bootstrap

```bash
git clone https://github.com/XavierAgostino/macstrap.git ~/Developer/workspaces/macstrap
bash ~/Developer/workspaces/macstrap/scripts/bootstrap.sh
```

The bootstrap is idempotent (safe to re-run) and does, in order:

1. Installs Homebrew if it is missing.
2. Clones this repo if it is missing.
3. Installs chezmoi and activates the gitleaks pre-commit hook.
4. Runs `chezmoi init`, which prompts for a profile (`personal` or `work`), name,
   email, and GitHub username. These are stored in
   `~/.config/chezmoi/chezmoi.toml` and are not committed.
5. Runs `chezmoi diff` then `chezmoi apply` to write managed dotfiles to `$HOME`.
6. Runs `mise install` to install runtimes from `~/.config/mise/config.toml`.
7. Runs `brew bundle` for `Brewfile.core`, the app set, and the active profile's
   Brewfile.
8. Runs `dev-doctor` as a health check.

> [!TIP]
> Skip the profile prompt with `PROFILE=work`, and skip the GUI apps with `APPS=0`.

## 3. Open a new terminal

Run `exec zsh`, or open a new Ghostty window, to load the new shell.

## 4. Post-bootstrap (manual, deliberate)

- **1Password:** open the app and sign in (the app and CLI ship in `Brewfile.core`).
  Verify the CLI with `op vault list`.
- **GitHub:** run `gh auth login`. On a work machine, add the work account (see
  [work-separation.md](work-separation.md)).
- **AI config:** deploy assistant instructions per [ai/README.md](../ai/README.md).
- **Commit signing** (optional, recommended): see [work-separation.md](work-separation.md).
- **Terminal:** set Ghostty as your default terminal.

## 5. Verify

The bootstrap links the `macstrap` CLI onto your PATH, so after opening a new
terminal:

```bash
macstrap doctor   # health check
macstrap report   # what macstrap manages
chezmoi verify    # exits 0 when $HOME matches the source
```

`macstrap doctor` should report chezmoi state clean, mise listing Node, and tools
resolving to Homebrew and mise paths.

## 6. Optional CLIs (per project, not per machine)

The core toolchain stays lean by design. Project-specific CLIs — cloud, database,
deploy, Kubernetes, and so on — are **discovery, not default install**: nothing in
the catalog ships with the base bootstrap. Add them when a project needs them:

```bash
macstrap cli                  # interactive, grouped picker
macstrap cli backend          # install a whole group
macstrap cli backend,cloud    # multiple groups
macstrap cli supabase,stripe  # exact tools
macstrap cli --list           # browse the full catalog
```

Each run installs immediately **and** appends your choice to `brew/selected.cli`.
The installer replays that file on the next machine, so your CLI stack is part of
your reproducible setup rather than a one-off `brew install`. `macstrap report`
lists what's recorded and whether it's installed.

The catalog lives in [`brew/cli.catalog`](../brew/cli.catalog) as
`key|formula|kind|categories|description` rows (the same schema as
`brew/apps.catalog`). Add a line to extend it — CI enforces that nothing here
duplicates `Brewfile.core`.

| Group | Tools |
| --- | --- |
| `deploy` | vercel · netlify · fly · railway |
| `backend` | supabase · stripe · redis · grpcurl |
| `database` | psql (libpq) · neon · duckdb |
| `cloud` | aws · cloudflared |
| `kubernetes` | kubectl · helm · k9s |
| `infra` | opentofu · terraform · pulumi |
| `security` | trivy · sops · age · cosign |
| `ai` | ollama · llm · aider |
| `api` | httpie · yq |
| `power-user` | lazygit · atuin · direnv · hyperfine · watchexec · just |
