#!/usr/bin/env bash
#
# macstrap security check. Read-only posture summary.
#
set -uo pipefail
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/workspaces/macstrap}"

g=$'\033[32m'; y=$'\033[33m'; x=$'\033[0m'
row() { printf '  %-24s %s%s%s\n' "$1" "$2" "$3" "$x"; }
good() { row "$1" "$g" "$2"; }
warn() { row "$1" "$y" "$2"; }

echo "== macstrap security check =="
echo

# Secrets in the repo
if ! command -v gitleaks >/dev/null 2>&1; then
  warn "secrets (gitleaks):" "gitleaks not installed"
elif gitleaks detect --source "$DOTFILES_DIR" --no-banner >/dev/null 2>&1; then
  good "secrets (gitleaks):" "clean"
else
  warn "secrets (gitleaks):" "findings (run: gitleaks detect)"
fi

# Commit signing
if [[ "$(git config --global commit.gpgsign 2>/dev/null || true)" == "true" ]]; then
  good "commit signing:" "on"
else
  warn "commit signing:" "off"
fi

# Pre-commit hook
if [[ "$(git -C "$DOTFILES_DIR" config core.hooksPath 2>/dev/null || true)" == "scripts/hooks" ]]; then
  good "pre-commit hook:" "active"
else
  warn "pre-commit hook:" "not set (run bootstrap)"
fi

# 1Password
if ! command -v op >/dev/null 2>&1; then
  warn "1Password CLI:" "not installed"
elif op vault list >/dev/null 2>&1; then
  good "1Password CLI:" "signed in"
else
  warn "1Password CLI:" "locked / signed out"
fi

# GitHub auth
if gh auth status >/dev/null 2>&1; then
  good "GitHub auth:" "authenticated"
else
  warn "GitHub auth:" "not authenticated"
fi
