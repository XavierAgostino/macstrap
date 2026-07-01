<div align="center">

<h1><picture><source media="(prefers-color-scheme: dark)" srcset=".github/assets/logos/apple-dark.svg"><img src=".github/assets/logos/apple-light.svg" height="26" alt=""/></picture>&nbsp; macstrap</h1>

### Bootstrap a modern macOS dev environment, in one command

[![CI](https://github.com/XavierAgostino/macstrap/actions/workflows/ci.yml/badge.svg)](https://github.com/XavierAgostino/macstrap/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform](https://img.shields.io/badge/macOS-Apple%20Silicon-000000?logo=apple&logoColor=white)
![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)

A reproducible, **profile-aware** macOS setup built on **chezmoi** and **mise**.
Secrets stay out of git, work and personal machines stay cleanly separated, and a
brand-new Mac is fully configured in minutes.

<br/>

<img src=".github/assets/demo.gif" width="780" alt="macstrap demo"/>

</div>

---

## Quick start

One line installs Homebrew, clones the repo, sets everything up, and links the
`macstrap` command onto your PATH:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/XavierAgostino/macstrap/main/install.sh)"
```

Open a new terminal, and you have the `macstrap` CLI:

```bash
macstrap install              # default stack (asks: personal or work?)
macstrap install --minimal    # shell, git, chezmoi, mise, CLI core only
macstrap install --work --apps
macstrap doctor               # health check
macstrap apps                 # pick GUI apps interactively
macstrap update               # pull the latest and apply
macstrap diff                 # preview pending changes
```

> [!TIP]
> Preview any run without touching your machine: `macstrap install --dry-run`.
> Run `macstrap help` for the full command list.

`macstrap apps` (and `macstrap install --apps`) let you pick exactly what to install:

<div align="center">
<img src=".github/assets/demo-apps.gif" width="780" alt="macstrap interactive app picker"/>
</div>

<details>
<summary><b>Manual setup and advanced env vars</b></summary>

Prefer to see each step, or automating without the CLI:

```bash
# Homebrew (also installs git via Xcode CLT)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# Clone and bootstrap
git clone https://github.com/XavierAgostino/macstrap.git ~/Developer/workspaces/macstrap
bash ~/Developer/workspaces/macstrap/scripts/bootstrap.sh
```

The CLI just sets env vars, which agents and CI can pass directly:
`MODE=minimal|default|interactive|headless|doctor`, `PROFILE=personal|work`,
`APPS=0|default|interactive|a,b,c`, `DRY_RUN=1`. For example
`PROFILE=work APPS=cursor,orbstack,tableplus bash scripts/bootstrap.sh`.
See [`docs/AGENT-USAGE.md`](docs/AGENT-USAGE.md).

</details>

## What you get

- **Modern shell**: zsh with the [Starship](https://starship.rs) prompt,
  autosuggestions, syntax highlighting, and a clean modular config.
- **One runtime manager**: [mise](https://mise.jdx.dev) handles Node, Python and
  more *per project* (`.nvmrc` / `.tool-versions` aware). No nvm/pyenv soup.
- **A great CLI toolbox**: `eza`, `bat`, `fd`, `ripgrep`, `fzf`, `zoxide`,
  `delta`, `jq`, `tmux`, preconfigured.
- **Terminal**: [Ghostty](https://ghostty.org) with a tuned config.
- **Personal and work profiles**: one repo; the right identity, packages, and
  commit signing per machine, chosen at setup.
- **Secrets done right**: [1Password](https://1password.com) integration plus a
  `gitleaks` pre-commit hook, so a credential can never land in git.
- **Signed commits**: SSH commit signing via 1Password (the verified badge on GitHub).
- **AI assistant config**: a starter `CLAUDE.md` / `AGENTS.md` for Claude Code,
  Codex, and Cursor.
- **macOS defaults**: an opt-in script for sensible Finder, keyboard, and
  screenshot preferences.
- **Tested in CI**: shellcheck and a chezmoi render check on every push.

## What's installed

**Toolchain (always):** `chezmoi` · `mise` · `starship` · `ghostty` · `zsh`
(+ autosuggestions & syntax-highlighting) · `git` + `delta` · `gh` · `eza` ·
`bat` · `fd` · `ripgrep` · `fzf` · `zoxide` · `jq` · `tmux` · `pnpm` · `uv` ·
`1password` + `1password-cli`

**Apps** installed out of the box:

<div align="center">
<table>
  <tr>
    <td align="center" width="104"><picture><source media="(prefers-color-scheme: dark)" srcset=".github/assets/logos/cursor-dark.svg"><img src=".github/assets/logos/cursor.svg" height="36" alt=""/></picture><br/><sub><b>Cursor</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/vscode.svg" height="36" alt=""/><br/><sub><b>VS Code</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/claude.svg" height="36" alt=""/><br/><sub><b>Claude Code</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/ghostty.svg" height="36" alt=""/><br/><sub><b>Ghostty</b></sub></td>
  </tr>
  <tr>
    <td align="center" width="104"><img src=".github/assets/logos/chrome.svg" height="36" alt=""/><br/><sub><b>Chrome</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/raycast.svg" height="36" alt=""/><br/><sub><b>Raycast</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/rectangle.png" height="36" alt=""/><br/><sub><b>Rectangle</b></sub></td>
    <td align="center" width="104"><picture><source media="(prefers-color-scheme: dark)" srcset=".github/assets/logos/onepassword-dark.svg"><img src=".github/assets/logos/onepassword.svg" height="36" alt=""/></picture><br/><sub><b>1Password</b></sub></td>
  </tr>
  <tr>
    <td align="center" width="104"><img src=".github/assets/logos/orbstack.png" height="36" alt=""/><br/><sub><b>OrbStack</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/tableplus.png" height="36" alt=""/><br/><sub><b>TablePlus</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/figma.svg" height="36" alt=""/><br/><sub><b>Figma</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/slack.svg" height="36" alt=""/><br/><sub><b>Slack</b></sub></td>
  </tr>
  <tr>
    <td align="center" width="104"><img src=".github/assets/logos/zoom.svg" height="36" alt=""/><br/><sub><b>Zoom</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/notion.svg" height="36" alt=""/><br/><sub><b>Notion</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/obsidian.svg" height="36" alt=""/><br/><sub><b>Obsidian</b></sub></td>
    <td align="center" width="104"><img src=".github/assets/logos/spotify.svg" height="36" alt=""/><br/><sub><b>Spotify</b></sub></td>
  </tr>
</table>
</div>

> [!TIP]
> Edit `brew/Brewfile.{core,apps,personal,work}` to make the toolset yours.
> `Brewfile.apps` has more options commented out.

## Structure

```
macstrap/
├── bin/macstrap                  # the CLI (symlinked to ~/.local/bin)
├── private_dot_zshrc.tmpl        # -> ~/.zshrc       (chezmoi templates)
├── dot_config/                   # -> ~/.config/*    (starship, ghostty, mise, zsh, git)
├── dot_gitconfig.tmpl            # -> ~/.gitconfig   (identity from profile)
├── brew/Brewfile.{core,apps,personal,work} + apps.catalog
├── scripts/                      # bootstrap, doctor, report, uninstall, security, hooks
├── ai/                           # AI assistant config (Claude / Codex / Cursor)
├── docs/                         # setup, decisions, troubleshooting, work/personal, agents
└── .github/workflows/ci.yml
```

## Profiles (personal vs work)

`chezmoi init` asks for a **profile** and identity. That one choice drives your
git identity, which Brewfiles install, and commit signing, so the same repo
configures a personal laptop and a locked-down work machine correctly. See
[`docs/work-separation.md`](docs/work-separation.md).

> [!IMPORTANT]
> With signing enabled, commits are signed through 1Password, so **1Password must
> be unlocked** to commit (a quick Touch ID prompt). Bypass a single commit with
> `git commit --no-gpg-sign`.

## Make it yours

1. Fork this repo.
2. Edit the Brewfiles, `dot_config/*`, and `ai/*` to taste.
3. Run `REPO_SLUG=you/macstrap bash scripts/bootstrap.sh` (or clone your fork and
   run the bootstrap).

> [!NOTE]
> Your name, email, and signing key are **never committed**: they live in
> machine-local chezmoi config, so a fork is generic by default.

## Maintenance and safety

Every action is previewable and reversible:

```bash
macstrap report        # what macstrap manages on this machine
macstrap security      # secrets, signing, hook, op/gh posture
macstrap doctor --json # machine-readable health
macstrap uninstall     # dry-run back-out of managed dotfiles (--apply to perform)
```

`uninstall.sh` backs up every file before removing it and never touches Homebrew
packages, 1Password, runtimes, or your data.

## Why it's built this way

See [`docs/DECISIONS.md`](docs/DECISIONS.md) for short notes on why chezmoi over
symlinks, mise over nvm/pyenv, profiles over branches, and more.

## Docs

- [`docs/SETUP.md`](docs/SETUP.md): detailed setup
- [`docs/DECISIONS.md`](docs/DECISIONS.md): design rationale
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md): fixes and recovery
- [`docs/work-separation.md`](docs/work-separation.md): profiles, signing, compliance

## License

[MIT](LICENSE): fork it, ship it, make it yours.
