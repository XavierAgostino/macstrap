<div align="center">

# macstrap

### Bootstrap a modern macOS dev environment — in one command.

[![CI](https://github.com/XavierAgostino/macstrap/actions/workflows/ci.yml/badge.svg)](https://github.com/XavierAgostino/macstrap/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform](https://img.shields.io/badge/macOS-Apple%20Silicon-000000?logo=apple&logoColor=white)
![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)

A reproducible, **profile-aware** macOS setup built on **chezmoi** and **mise**.
Secrets stay out of git, work and personal machines stay cleanly separated, and a
brand-new Mac is fully configured in minutes.

<br/>

![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)
![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?logo=homebrew&logoColor=white)
![chezmoi](https://img.shields.io/badge/chezmoi-2B9FE1?logo=chezmoi&logoColor=white)
![mise](https://img.shields.io/badge/mise-FA5B3D?logoColor=white)
![Starship](https://img.shields.io/badge/Starship-DD0B78?logo=starship&logoColor=white)
![Ghostty](https://img.shields.io/badge/Ghostty-1B1B1D?logoColor=white)
![Zsh](https://img.shields.io/badge/Zsh-1A2C34?logo=zsh&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?logo=git&logoColor=white)
![1Password](https://img.shields.io/badge/1Password-3B66BC?logo=1password&logoColor=white)

</div>

---

## Quick start

```bash
# 1. Homebrew (also installs git via Xcode CLT)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. Clone + bootstrap (asks: personal or work?)
git clone https://github.com/XavierAgostino/macstrap.git ~/Developer/workspaces/macstrap
bash ~/Developer/workspaces/macstrap/scripts/bootstrap.sh

# 3. Open a new terminal (or: exec zsh)
```

The bootstrap is **idempotent** — safe to re-run anytime. Skip the GUI apps with
`APPS=0`, or preset the profile with `PROFILE=work`.

## What you get

- **Modern shell** — zsh with the [Starship](https://starship.rs) prompt,
  autosuggestions, syntax highlighting, and a clean modular config.
- **One runtime manager** — [mise](https://mise.jdx.dev) handles Node, Python and
  more *per project* (`.nvmrc` / `.tool-versions` aware). No nvm/pyenv soup.
- **A great CLI toolbox** — `eza`, `bat`, `fd`, `ripgrep`, `fzf`, `zoxide`,
  `delta`, `jq`, `tmux`, preconfigured.
- **Terminal** — [Ghostty](https://ghostty.org) with a tuned config.
- **Personal and work profiles** — one repo; the right identity, packages, and
  commit signing per machine, chosen at setup.
- **Secrets done right** — [1Password](https://1password.com) integration plus a
  `gitleaks` pre-commit hook, so a credential can never land in git.
- **Signed commits** — SSH commit signing via 1Password (the verified badge on GitHub).
- **AI assistant config** — a starter `CLAUDE.md` / `AGENTS.md` for Claude Code,
  Codex, and Cursor.
- **macOS defaults** — an opt-in script for sensible Finder, keyboard, and
  screenshot preferences.
- **Tested in CI** — shellcheck and a chezmoi render check on every push.

## What's installed

**Toolchain (always):**

![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?logo=homebrew&logoColor=white)
![mise](https://img.shields.io/badge/mise-FA5B3D?logoColor=white)
![Starship](https://img.shields.io/badge/Starship-DD0B78?logo=starship&logoColor=white)
![Ghostty](https://img.shields.io/badge/Ghostty-1B1B1D?logoColor=white)
![pnpm](https://img.shields.io/badge/pnpm-F69220?logo=pnpm&logoColor=white)
![uv](https://img.shields.io/badge/uv-DE5FE9?logoColor=white)
![GitHub CLI](https://img.shields.io/badge/gh-181717?logo=github&logoColor=white)
![tmux](https://img.shields.io/badge/tmux-1BB91F?logo=tmux&logoColor=white)

**Apps (the `Brewfile.apps` starter — trim freely):**

![Cursor](https://img.shields.io/badge/Cursor-000000?logo=cursor&logoColor=white)
![VS Code](https://img.shields.io/badge/VS%20Code-007ACC?logo=visualstudiocode&logoColor=white)
![Chrome](https://img.shields.io/badge/Chrome-4285F4?logo=googlechrome&logoColor=white)
![Firefox](https://img.shields.io/badge/Firefox-FF7139?logo=firefoxbrowser&logoColor=white)
![Raycast](https://img.shields.io/badge/Raycast-FF6363?logo=raycast&logoColor=white)
![OrbStack](https://img.shields.io/badge/OrbStack-1A1A1A?logoColor=white)
![TablePlus](https://img.shields.io/badge/TablePlus-2A6FF4?logoColor=white)
![Obsidian](https://img.shields.io/badge/Obsidian-7C3AED?logo=obsidian&logoColor=white)
![Notion](https://img.shields.io/badge/Notion-000000?logo=notion&logoColor=white)
![Figma](https://img.shields.io/badge/Figma-F24E1E?logo=figma&logoColor=white)
![Slack](https://img.shields.io/badge/Slack-4A154B?logo=slack&logoColor=white)
![Discord](https://img.shields.io/badge/Discord-5865F2?logo=discord&logoColor=white)
![Spotify](https://img.shields.io/badge/Spotify-1DB954?logo=spotify&logoColor=white)

Edit `brew/Brewfile.{core,apps,personal,work}` to make it yours.

## Structure

```
macstrap/
├── private_dot_zshrc.tmpl        # -> ~/.zshrc       (chezmoi templates)
├── dot_config/                   # -> ~/.config/*    (starship, ghostty, mise, zsh, git)
├── dot_gitconfig.tmpl            # -> ~/.gitconfig   (identity from profile)
├── brew/Brewfile.{core,apps,personal,work}
├── scripts/                      # bootstrap, doctor, macos-defaults, git hooks
├── ai/                           # AI assistant config (Claude / Codex / Cursor)
├── docs/                         # setup, decisions, troubleshooting, work/personal
└── .github/workflows/ci.yml
```

## Profiles (personal vs work)

`chezmoi init` asks for a **profile** and identity. That one choice drives your
git identity, which Brewfiles install, and commit signing — so the same repo
configures a personal laptop and a locked-down work machine correctly. See
[`docs/work-separation.md`](docs/work-separation.md).

## Make it yours

1. Fork this repo.
2. Edit the Brewfiles, `dot_config/*`, and `ai/*` to taste.
3. Run `REPO_SLUG=you/macstrap bash scripts/bootstrap.sh` (or clone your fork and
   run the bootstrap).

Your name, email, and signing key are **never committed** — they live in
machine-local chezmoi config, so a fork is generic by default.

## Why it's built this way

See [`docs/DECISIONS.md`](docs/DECISIONS.md) for short notes on why chezmoi over
symlinks, mise over nvm/pyenv, profiles over branches, and more.

## Docs

- [`docs/SETUP.md`](docs/SETUP.md) — detailed setup
- [`docs/DECISIONS.md`](docs/DECISIONS.md) — design rationale
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — fixes and recovery
- [`docs/work-separation.md`](docs/work-separation.md) — profiles, signing, compliance

## License

[MIT](LICENSE) — fork it, ship it, make it yours.
