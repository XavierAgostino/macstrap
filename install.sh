#!/usr/bin/env bash
#
# macstrap one-line installer. Small bootstrapper: installs Homebrew, clones the
# repo, and hands off to scripts/bootstrap.sh. Reads the same env vars.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/XavierAgostino/macstrap/main/install.sh)"
#
#   NONINTERACTIVE=1 PROFILE=personal MODE=minimal bash install.sh
#
set -euo pipefail

REPO_SLUG="${REPO_SLUG:-XavierAgostino/macstrap}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/workspaces/macstrap}"
NONINTERACTIVE="${NONINTERACTIVE:-0}"

cat <<EOF

macstrap will:
  1. Install Homebrew if it is missing
  2. Clone $REPO_SLUG to $DOTFILES_DIR
  3. Run scripts/bootstrap.sh (mode: ${MODE:-default})

EOF

if [[ "$NONINTERACTIVE" != "1" ]]; then
  printf "Continue? [y/N] "
  read -r reply </dev/tty || reply="n"
  [[ "$reply" =~ ^[Yy]$ ]] || {
    echo "Aborted."
    exit 1
  }
fi

command -v brew >/dev/null 2>&1 ||
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "https://github.com/$REPO_SLUG.git" "$DOTFILES_DIR"
fi

exec bash "$DOTFILES_DIR/scripts/bootstrap.sh"
