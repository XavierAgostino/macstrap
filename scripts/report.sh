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

echo "-- Optional CLIs (macstrap cli) --"
sel="$DOTFILES_DIR/brew/selected.cli"
catalog="$DOTFILES_DIR/brew/cli.catalog"
if [[ -f "$sel" ]] && grep -qvE '^[[:space:]]*(#|$)' "$sel"; then
  # For each recorded key, resolve its formula and show installed / missing.
  sed 's/#.*//; s/[[:space:]]//g; /^$/d' "$sel" | while IFS= read -r key; do
    formula="$(awk -F'|' -v k="$key" '!/^[[:space:]]*#/ && $1==k { print $2; exit }' "$catalog")"
    [[ -z "$formula" ]] && formula="$key"
    if brew list --formula "$formula" >/dev/null 2>&1 || brew list --cask "$formula" >/dev/null 2>&1; then
      printf '  %-14s installed\n' "$key"
    else
      printf '  %-14s recorded (not installed — run: macstrap install)\n' "$key"
    fi
  done
else
  echo "  none recorded — add some with: macstrap cli"
fi
echo

echo "-- Profile --"
echo "  $(chezmoi execute-template '{{ .profile }}' 2>/dev/null || echo unknown)"
echo

echo "Preview pending changes:  chezmoi diff"
echo "Back out dotfiles:        bash scripts/uninstall.sh --dry-run"
