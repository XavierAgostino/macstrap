#!/usr/bin/env bash
set -euo pipefail

echo "== macOS Dev Doctor =="
echo "Date: $(date)"
echo

# Resolve mise-managed runtimes (node, etc.) even in this non-interactive shell.
[[ -d "$HOME/.local/share/mise/shims" ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"

echo "-- System --"
sw_vers
echo "arch: $(uname -m)"
echo "shell: ${SHELL:-unknown}"
echo

echo "-- Homebrew --"
if command -v brew >/dev/null 2>&1; then
  echo "brew: $(command -v brew)"
  echo "prefix: $(brew --prefix)"
  brew doctor || true
else
  echo "brew not found"
fi
echo

echo "-- Resolution --"
for tool in chezmoi mise python3 node npm pnpm npx uv gh git ssh starship zoxide; do
  printf "%-9s -> " "$tool"
  command -v "$tool" || echo "not found"
done
echo

echo "-- Versions --"
chezmoi --version 2>/dev/null | sed -n '1p' || true
mise --version 2>/dev/null || true
python3 --version 2>/dev/null || true
node --version 2>/dev/null || true
pnpm --version 2>/dev/null || true
uv --version 2>/dev/null || true
gh --version 2>/dev/null | sed -n '1p' || true
git --version 2>/dev/null || true
echo

echo "-- mise tools --"
mise ls 2>/dev/null || echo "mise not active"
echo

echo "-- chezmoi --"
if command -v chezmoi >/dev/null 2>&1; then
  echo "source:  $(chezmoi source-path 2>/dev/null)"
  echo "profile: $(chezmoi execute-template '{{ .profile }}' 2>/dev/null)"
  chezmoi verify >/dev/null 2>&1 && echo "state:   clean (live matches source)" || echo "state:   DRIFT — run 'chezmoi diff'"
fi
echo

echo "-- PATH (deduped login shell) --"
zsh -lc 'typeset -U path PATH; print -l $path'
