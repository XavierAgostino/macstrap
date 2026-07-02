# Setup (fresh Mac)

Full walkthrough for a new machine. Short version: [README](../README.md).
Doc index: [docs/README.md](README.md).

## Prerequisites

- Apple Silicon Mac, current macOS.
- Internet access.

> [!NOTE]
> On a work machine, complete IT/MDM enrollment first and confirm admin rights.

## 1. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Homebrew also installs the Xcode Command Line Tools (git).

## 2. Clone and bootstrap

```bash
git clone https://github.com/XavierAgostino/macstrap.git ~/Developer/workspaces/macstrap
bash ~/Developer/workspaces/macstrap/scripts/bootstrap.sh
```

The bootstrap is idempotent and runs, in order:

1. Homebrew (if missing) and repo clone (if missing).
2. chezmoi + gitleaks pre-commit hook.
3. `chezmoi init` — profile (`personal` or `work`), name, email, GitHub username →
   `~/.config/chezmoi/chezmoi.toml` (not committed).
4. `chezmoi diff` then `chezmoi apply`.
5. `mise install` from `~/.config/mise/config.toml`.
6. `brew bundle` for `Brewfile.core`, apps, and profile Brewfile.
7. `dev-doctor` health check.

> [!TIP]
> `PROFILE=work` skips the profile prompt. `APPS=0` skips GUI apps.

## 3. Open a new terminal

Run `exec zsh`, or open a new Ghostty window.

## 4. Verify

Confirm the bootstrap applied cleanly:

```bash
macstrap doctor   # health check
macstrap report   # what macstrap manages
chezmoi verify    # $HOME matches source
```

Expect chezmoi clean, mise listing Node, tools on Homebrew/mise paths. Warnings
about 1Password or signing before post-bootstrap are normal.

## 5. Post-bootstrap

Complete these after verify:

- [ ] **1Password** — sign in; verify with `op vault list`
- [ ] **GitHub** — `gh auth login` (work account on a work machine — see
  [work-separation.md](work-separation.md))
- [ ] **Commit signing** (recommended) — [work-separation.md](work-separation.md)
- [ ] **AI config** — [ai/README.md](../ai/README.md)
- [ ] **Terminal** — set Ghostty as default
- [ ] **Cursor / VS Code** — open once after bootstrap so the Vesper extension
  installs; reload the window if the theme looks missing (`Cmd+Shift+P` →
  **Developer: Reload Window**). **Cmd+Shift+G** opens Ghostty from the editor.

## 6. Optional CLIs (per project, not per machine)

Discovery, not default install — add when a project needs them:

```bash
macstrap cli                  # interactive, grouped picker
macstrap cli backend          # install a whole group
macstrap cli backend,cloud    # multiple groups
macstrap cli supabase,stripe  # exact tools
macstrap cli --list           # browse the full catalog
```

Selections append to `brew/selected.cli` and replay on the next machine.
`macstrap report` lists recorded vs installed.

Catalog: [`brew/cli.catalog`](../brew/cli.catalog) (`key|formula|kind|categories|description`).
CI blocks duplicates of `Brewfile.core`.

| Group | Tools |
| --- | --- |
| `deploy` | vercel · netlify · fly · railway |
| `backend` | supabase · stripe · redis · grpcurl |
| `database` | psql (libpq) · neon · duckdb |
| `cloud` | aws · cloudflared |
| `kubernetes` | kubectl · helm · k9s |
| `infra` | opentofu · pulumi |
| `security` | trivy · sops · age · cosign |
| `ai` | ollama · llm · aider |
| `api` | httpie · yq |
| `power-user` | lazygit · atuin · direnv · hyperfine · watchexec · just |

## 7. Default toolchain and apps

**Core (always):** `chezmoi` · `mise` · `starship` · `ghostty` · `zsh`
(+ autosuggestions & syntax-highlighting) · `git` + `delta` · `gh` · `eza` ·
`bat` · `fd` · `ripgrep` · `fzf` · `zoxide` · `jq` · `tmux` · `pnpm` · `uv` ·
`1password` + `1password-cli`

**Default GUI apps:** Cursor, VS Code, Claude Code, Ghostty, Chrome, Raycast,
Rectangle, 1Password, OrbStack, TablePlus, Figma, Slack, Zoom, Notion,
Obsidian, Spotify — see [`brew/Brewfile.apps`](../brew/Brewfile.apps). More
options are commented out there.

Edit `brew/Brewfile.{core,apps,personal,work}` to customize.
