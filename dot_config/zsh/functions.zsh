# ~/.config/zsh/functions.zsh — shell functions. Managed by chezmoi.

DOTFILES="$HOME/Developer/workspaces/macstrap"

# Daily dev-environment health check.
morning-brew() {
  bash "$DOTFILES/scripts/dev-doctor.sh" "$@"
}

# Capture any edits to your dotfiles and push them — one command, no steps to
# remember. Edit ~/.zshrc (or any managed file) however you like, then run this.
#   dotsync              -> commit "sync dotfiles" + push
#   dotsync "add fzf opts"  -> custom commit message
dotsync() {
  chezmoi re-add >/dev/null || return 1     # pull live edits back into the source
  git -C "$DOTFILES" add -A
  if git -C "$DOTFILES" diff --cached --quiet; then
    echo "dotsync: nothing to sync."
    return 0
  fi
  git -C "$DOTFILES" commit -m "${1:-chore: sync dotfiles}" && git -C "$DOTFILES" push
}

# Install a Homebrew package AND record it in the right Brewfile, then push.
# Auto-detects formula vs cask. Defaults to the portable 'core' bucket.
#   brewadd ripgrep          -> Brewfile.core
#   brewadd raycast          -> Brewfile.core (detected as a cask)
#   brewadd -p stripe        -> Brewfile.personal
#   brewadd -w awscli        -> Brewfile.work
brewadd() {
  local bucket="core"
  while [[ "$1" == -* ]]; do
    case "$1" in
      -p|--personal) bucket="personal" ;;
      -w|--work)     bucket="work" ;;
      *) echo "brewadd: unknown flag $1"; return 1 ;;
    esac
    shift
  done
  [[ $# -gt 0 ]] || { echo "usage: brewadd [-p|-w] <pkg...>"; return 1; }
  brew install "$@" || return 1
  local file="$DOTFILES/brew/Brewfile.$bucket" pkg kind
  for pkg in "$@"; do
    if brew list --cask "$pkg" &>/dev/null; then kind="cask"; else kind="brew"; fi
    grep -qF "$kind \"$pkg\"" "$file" || echo "$kind \"$pkg\"" >> "$file"
  done
  git -C "$DOTFILES" add "brew/"
  if git -C "$DOTFILES" diff --cached --quiet; then
    echo "brewadd: installed; already recorded in Brewfile.$bucket."
    return 0
  fi
  git -C "$DOTFILES" commit -m "brew: add $* ($bucket)" && git -C "$DOTFILES" push
}

# Uninstall a Homebrew package AND remove it from the Brewfiles, then push.
brewrm() {
  [[ $# -gt 0 ]] || { echo "usage: brewrm <pkg...>"; return 1; }
  brew uninstall "$@" || return 1
  local pkg
  for pkg in "$@"; do
    sed -i '' "/^\(brew\|cask\) \"$pkg\"/d" "$DOTFILES"/brew/Brewfile.* 2>/dev/null
  done
  git -C "$DOTFILES" add "brew/"
  git -C "$DOTFILES" diff --cached --quiet && { echo "brewrm: removed; nothing recorded."; return 0; }
  git -C "$DOTFILES" commit -m "brew: remove $*" && git -C "$DOTFILES" push
}
