#!/usr/bin/env bash
#
# macstrap apps — read-only view of the GUI app catalog (brew/apps.catalog).
# This script lists and resolves; it installs nothing. Installation runs through
# the bootstrap app phase (`macstrap apps <selection>`), so the TUI reads the
# catalog here and triggers installs there.
#
# Usage:
#   macstrap apps --list            show the catalog, grouped by category
#   macstrap apps --list --json     the catalog as JSON (for the TUI / agents)
#   macstrap apps a,b,c --dry-run   resolve a selection, install nothing
#   macstrap apps a,b,c --json      resolve a selection to JSON keys
#
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/workspaces/macstrap}"
APPS_CATALOG="$DOTFILES_DIR/brew/apps.catalog"

# shared UI helpers (log / muted) + catalog + JSON
# shellcheck source=scripts/lib/ui.sh
. "$DOTFILES_DIR/scripts/lib/ui.sh"
# shellcheck source=scripts/lib/catalog.sh
. "$DOTFILES_DIR/scripts/lib/catalog.sh"
# shellcheck source=scripts/lib/json.sh
. "$DOTFILES_DIR/scripts/lib/json.sh"

usage() {
  cat <<'EOF'
macstrap apps: browse the GUI app catalog (read-only)

Usage:
  macstrap apps --list            show the catalog, grouped
  macstrap apps --list --json     the catalog as JSON
  macstrap apps a,b,c --dry-run   resolve a selection, install nothing
  macstrap apps a,b,c --json      resolve a selection to JSON keys

To install, run:  macstrap apps <category|a,b,c>   (or pick interactively)
EOF
}

# Print the catalog grouped by category, with descriptions.
list_catalog() {
  local cat
  echo "GUI apps (brew/apps.catalog):"
  for cat in $(catalog_categories "$APPS_CATALOG"); do
    printf '\n%s%s%s\n' "$b" "$cat" "$x"
    awk -F'|' -v c="$cat" '
      !/^[[:space:]]*#/ && NF >= 5 {
        n = split($4, a, ",")
        for (i = 1; i <= n; i++) { gsub(/^[ \t]+|[ \t]+$/, "", a[i]); if (a[i] == c) { printf "  %-16s %s\n", $1, $5; break } }
      }' "$APPS_CATALOG"
  done
  echo
  echo "Install:  macstrap apps <category>   |   macstrap apps app1,app2"
}

# macstrap.catalog/v1 — the full app catalog plus category and default state.
# See docs/JSON-CONTRACTS.md.
emit_catalog_json() {
  local cats=() defs=() c k
  while IFS= read -r c; do [[ -n "$c" ]] && cats+=("$c"); done < <(catalog_categories "$APPS_CATALOG")
  while IFS= read -r k; do [[ -n "$k" ]] && defs+=("$k"); done < <(catalog_keys "$APPS_CATALOG" default)
  printf '{"schema":"macstrap.catalog/v1","catalog":"apps","categories":%s,"defaults":%s,"items":%s}\n' \
    "$(json_str_array ${cats[@]+"${cats[@]}"})" \
    "$(json_str_array ${defs[@]+"${defs[@]}"})" \
    "$(catalog_json "$APPS_CATALOG")"
}

# macstrap.plan/v1 — a resolved selection (keys only), install nothing.
emit_plan_json() {
  local ks=() k
  while IFS= read -r k; do [[ -n "$k" ]] && ks+=("$k"); done < <(printf '%s\n' "$1" | sed '/^$/d')
  printf '{"schema":"macstrap.plan/v1","catalog":"apps","keys":%s}\n' \
    "$(json_str_array ${ks[@]+"${ks[@]}"})"
}

# --- argument handling ---
# apps.sh never installs, so --dry-run is accepted but redundant (the default).
JSON=0
args=()
for a in "$@"; do
  case "$a" in
    --json) JSON=1 ;;
    --dry-run | -n) ;;
    *) args+=("$a") ;;
  esac
done
set -- ${args[@]+"${args[@]}"}

case "${1:-}" in
  -h | --help | help)
    usage
    exit 0
    ;;
  -l | --list | list)
    [[ $JSON -eq 1 ]] && {
      emit_catalog_json
      exit 0
    }
    list_catalog
    exit 0
    ;;
esac

# No selection: JSON callers want the whole catalog; humans get usage.
if [[ $# -eq 0 ]]; then
  [[ $JSON -eq 1 ]] && {
    emit_catalog_json
    exit 0
  }
  usage
  exit 0
fi

# Resolve the selection (categories and/or keys) to a newline list of keys.
selection="$(catalog_resolve "$APPS_CATALOG" "$(
  IFS=,
  echo "$*"
)")"
keys="$(printf '%s\n' "$selection" | sed '/^$/d')"
count="$(printf '%s\n' "$keys" | grep -c . || true)"

if [[ $JSON -eq 1 ]]; then
  emit_plan_json "$keys"
  exit 0
fi

log "Plan: $count app(s) (dry run — nothing installed)"
# shellcheck disable=SC2046  # keys are single words; word-splitting is intended
catalog_describe "$APPS_CATALOG" $(printf '%s\n' "$keys")
muted "Install with:  macstrap apps $*"
