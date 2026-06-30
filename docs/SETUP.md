# Setup — fresh Mac

Detailed walkthrough of standing up a new machine from this repo. For the short
version see the README.

## Prerequisites

- Apple Silicon Mac, macOS current.
- Internet access. Sign in to the App Store / Apple ID as desired.
- On a **work** machine: complete any IT/MDM enrollment first, and confirm you
  have admin (or know what's restricted) before installing.

## 1. Homebrew + GitHub auth (the repo is private)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install gh && gh auth login        # personal GitHub account, HTTPS, browser
```

## 2. Clone + bootstrap

```bash
gh repo clone XavierAgostino/macstrap ~/Developer/workspaces/macstrap
bash ~/Developer/workspaces/macstrap/scripts/bootstrap.sh
```

The bootstrap is **idempotent** (safe to re-run) and does, in order:

1. Installs **Homebrew** if missing.
2. Clones this repo if missing.
3. Installs **chezmoi** and activates the gitleaks pre-commit hook.
4. `chezmoi init` — prompts for **profile** (`personal`/`work`), name, email,
   GitHub username (stored in `~/.config/chezmoi/chezmoi.toml`, not committed).
5. `chezmoi diff` then `chezmoi apply` — writes managed dotfiles to `$HOME`.
6. `mise install` — installs runtimes from `~/.config/mise/config.toml`.
7. `brew bundle` — `Brewfile.core` plus the active profile's Brewfile.
8. `dev-doctor` — health check.

To skip the profile prompt: `PROFILE=work bash scripts/bootstrap.sh`.

## 2. Open a new terminal

`exec zsh` or open a new Ghostty window to load the new shell.

## 3. Post-bootstrap (manual, deliberate)

- **1Password**: install the app + CLI, sign in (personal vault, or the company
  vault on a work machine). Verify with `op vault list`.
- **GitHub auth**: `gh auth login` (add the work account on a work machine — see
  `work-separation.md`).
- **AI config**: deploy assistant instructions per `ai/README.md`.
- **Commit signing** (optional, recommended for work): see `work-separation.md`.
- **Fonts/terminal**: Ghostty + Geist Mono come via `Brewfile.core`; set Ghostty
  as your default terminal.

## 4. Verify

```bash
doctor        # or: bash scripts/dev-doctor.sh
chezmoi verify   # exits 0 when $HOME matches the source
```

`dev-doctor` should show chezmoi state **clean**, mise listing Node, and tools
resolving to Homebrew / mise paths.
