#!/usr/bin/env bash
#
# macstrap report. Show what macstrap manages on this machine. Read-only.
#
#   report.sh            human-readable summary
#   report.sh --json     machine-readable summary (macstrap.report/v1)
#
set -euo pipefail
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/workspaces/macstrap}"
[[ -d "$HOME/.local/share/mise/shims" ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"
# shellcheck source=scripts/lib/json.sh
. "$DOTFILES_DIR/scripts/lib/json.sh"

CORE="$DOTFILES_DIR/brew/Brewfile.core"
APPS_GEN="$DOTFILES_DIR/brew/generated/Brewfile.apps.local"
CLI_SELECTED="$DOTFILES_DIR/brew/selected.cli"
CLI_CATALOG="$DOTFILES_DIR/brew/cli.catalog"

# Resolve a recorded CLI key to installed | recorded (mirrors the human view).
cli_status() {
  local key="$1" formula
  formula="$(awk -F'|' -v k="$key" '!/^[[:space:]]*#/ && $1==k { print $2; exit }' "$CLI_CATALOG")"
  [[ -z "$formula" ]] && formula="$key"
  if brew list --formula "$formula" >/dev/null 2>&1 || brew list --cask "$formula" >/dev/null 2>&1; then
    echo installed
  else
    echo recorded
  fi
}

# macstrap.report/v1 — see docs/JSON-CONTRACTS.md.
emit_json() {
  local profile core apps dotfiles cli="" key
  profile="$(chezmoi execute-template '{{ .profile }}' 2>/dev/null || echo unknown)"
  core="$(grep -cE '^(brew|cask) ' "$CORE" 2>/dev/null || echo 0)"
  apps=0
  [[ -f "$APPS_GEN" ]] && apps="$(grep -c '^cask ' "$APPS_GEN" 2>/dev/null || echo 0)"
  dotfiles=0
  command -v chezmoi >/dev/null 2>&1 && dotfiles="$(chezmoi managed 2>/dev/null | grep -c . || echo 0)"
  if [[ -f "$CLI_SELECTED" ]] && command -v brew >/dev/null 2>&1; then
    while IFS= read -r key; do
      [[ -z "$key" ]] && continue
      cli+="${cli:+,}{\"key\":$(json_str "$key"),\"status\":$(json_str "$(cli_status "$key")")}"
    done < <(sed 's/#.*//; s/[[:space:]]//g; /^$/d' "$CLI_SELECTED")
  fi
  printf '{"schema":"macstrap.report/v1","profile":%s,"homebrew":{"core":%d,"apps":%d},"dotfiles_count":%d,"cli":[%s]}\n' \
    "$(json_str "$profile")" "$core" "$apps" "$dotfiles" "$cli"
}

if [[ "${1:-}" == "--json" ]]; then
  emit_json
  exit 0
fi

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
