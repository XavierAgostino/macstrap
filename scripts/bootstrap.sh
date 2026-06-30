#!/usr/bin/env bash
#
# macstrap — bootstrap a modern macOS dev environment. Idempotent (safe to re-run).
# Flow: Homebrew -> clone -> chezmoi -> init + apply -> mise runtimes
#       -> brew bundle (core + apps + profile) -> verify.
#
# Usage:
#   bash scripts/bootstrap.sh
#   PROFILE=work bash scripts/bootstrap.sh     # skip the profile prompt
#   APPS=0 bash scripts/bootstrap.sh           # skip the GUI app bundle
#
# Forking? Set REPO_SLUG to your fork:  REPO_SLUG=you/macstrap bash scripts/bootstrap.sh
#
set -euo pipefail

REPO_SLUG="${REPO_SLUG:-XavierAgostino/macstrap}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/workspaces/macstrap}"
REPO_URL="${REPO_URL:-https://github.com/$REPO_SLUG.git}"
PROFILE="${PROFILE:-}"     # personal|work — chezmoi prompts if unset on first init
APPS="${APPS:-1}"          # 1 = also install the GUI app bundle (Brewfile.apps)

log() { printf "\n\033[1;34m==>\033[0m %s\n" "$*"; }

# 1. Homebrew --------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. Clone the repo if missing (public repo — no auth needed) ---------------
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  log "Cloning $REPO_SLUG -> $DOTFILES_DIR"
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# 3. chezmoi + secret-scan git hook ----------------------------------------
command -v chezmoi >/dev/null 2>&1 || { log "Installing chezmoi..."; brew install chezmoi; }
git -C "$DOTFILES_DIR" config core.hooksPath scripts/hooks || true

# 4. Init chezmoi (prompts profile/name/email/githubUser on first run) ------
log "Initializing chezmoi (source: $DOTFILES_DIR)"
chezmoi init --source="$DOTFILES_DIR"

# 5. Preview, then apply ----------------------------------------------------
log "Preview (chezmoi diff):"; chezmoi diff || true
log "Applying dotfiles"; chezmoi apply

# 6. Runtimes via mise ------------------------------------------------------
command -v mise >/dev/null 2>&1 || brew install mise
log "Installing runtimes via mise"; mise install || true

# 7. Homebrew packages: core (+ apps) (+ active profile) --------------------
[[ -z "$PROFILE" ]] && PROFILE="$(chezmoi execute-template '{{ .profile }}' 2>/dev/null || true)"
log "Installing Homebrew packages: core${APPS:+ + apps}${PROFILE:+ + $PROFILE}"
brew bundle --file="$DOTFILES_DIR/brew/Brewfile.core" || true
[[ "$APPS" == "1" ]] && brew bundle --file="$DOTFILES_DIR/brew/Brewfile.apps" || true
case "$PROFILE" in
  personal) brew bundle --file="$DOTFILES_DIR/brew/Brewfile.personal" || true ;;
  work)     brew bundle --file="$DOTFILES_DIR/brew/Brewfile.work" || true ;;
  *) echo "No profile detected — set PROFILE=personal|work to install its Brewfile." ;;
esac

# 8. Verify -----------------------------------------------------------------
log "Running dev-doctor"; bash "$DOTFILES_DIR/scripts/dev-doctor.sh" || true

log "Done. Open a new terminal (or run 'exec zsh') to load the shell."
echo "Optional: bash scripts/macos-defaults.sh   # apply macOS system preferences"
