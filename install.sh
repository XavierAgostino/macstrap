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
  4. Install the macstrap TUI binary (optional; the shell engine works without it)

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

# The shell engine is the guaranteed first-install path; run it to completion.
bash "$DOTFILES_DIR/scripts/bootstrap.sh"

# Then install the prebuilt TUI binary as an enhancement. Non-fatal: if there's
# no release for this platform (or we're offline), the shell engine still works
# via "$DOTFILES_DIR/bin/macstrap".
if ! bash "$DOTFILES_DIR/scripts/install-binary.sh"; then
  echo
  echo "macstrap TUI binary not installed — use the shell engine at:"
  echo "  $DOTFILES_DIR/bin/macstrap"
fi
