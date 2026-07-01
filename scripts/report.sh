#!/usr/bin/env bash
#
# macstrap report. Show what macstrap manages on this machine. Read-only.
#
set -euo pipefail
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/workspaces/macstrap}"
[[ -d "$HOME/.local/share/mise/shims" ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"

echo "== macstrap report =="
echo

echo "-- Managed dotfiles (chezmoi) --"
if command -v chezmoi >/dev/null 2>&1; then
  chezmoi managed 2>/dev/null | sed 's|^|  ~/|'
else
  echo "  (chezmoi not installed)"
fi
echo

echo "-- Runtimes (mise) --"
mise ls 2>/dev/null | sed 's|^|  |' || echo "  (mise not active)"
echo

echo "-- Homebrew --"
core="$DOTFILES_DIR/brew/Brewfile.core"
echo "  core:  $(grep -cE '^(brew|cask) ' "$core" 2>/dev/null || echo 0) packages (Brewfile.core)"
gen="$DOTFILES_DIR/brew/generated/Brewfile.apps.local"
[[ -f "$gen" ]] && echo "  apps:  $(grep -c '^cask ' "$gen" 2>/dev/null || echo 0) from your last selection"
echo

echo "-- Profile --"
echo "  $(chezmoi execute-template '{{ .profile }}' 2>/dev/null || echo unknown)"
echo

echo "Preview pending changes:  chezmoi diff"
echo "Back out dotfiles:        bash scripts/uninstall.sh --dry-run"
