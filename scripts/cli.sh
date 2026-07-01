#!/usr/bin/env bash
#
# macstrap cli — install optional, project-specific developer CLIs from
# brew/cli.catalog. Discovery, not default install: nothing here ships with the
# base bootstrap. Selections are recorded in brew/selected.cli so a fresh Mac
# replays them (see scripts/bootstrap.sh: install_selected_cli).
#
# Usage:
#   macstrap cli                   pick interactively (grouped picker)
#   macstrap cli backend           install a whole category
#   macstrap cli backend,cloud     install multiple categories
#   macstrap cli supabase,stripe   install exact tools
#   macstrap cli --list            print the catalog, grouped by category
#
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/workspaces/macstrap}"
CLI_CATALOG="$DOTFILES_DIR/brew/cli.catalog"
CLI_SELECTED="$DOTFILES_DIR/brew/selected.cli"

# shared UI helpers (log / ok / warn / muted / run_logged) + catalog + JSON
# shellcheck source=scripts/lib/ui.sh
. "$DOTFILES_DIR/scripts/lib/ui.sh"
# shellcheck source=scripts/lib/catalog.sh
. "$DOTFILES_DIR/scripts/lib/catalog.sh"
# shellcheck source=scripts/lib/json.sh
. "$DOTFILES_DIR/scripts/lib/json.sh"

usage() {
  cat <<'EOF'
macstrap cli: install optional developer CLIs (discovery, not default)

Usage:
  macstrap cli                   pick interactively
  macstrap cli <category>        install a category (e.g. backend, cloud, ai)
  macstrap cli a,b,c             install categories and/or exact tools
  macstrap cli --list            show the catalog, grouped
  macstrap cli --list --json     the catalog as JSON (for the TUI / agents)
  macstrap cli a,b,c --dry-run   resolve the selection, install nothing

Recorded selections live in brew/selected.cli and replay on a fresh machine.
EOF
}

# macstrap.catalog/v1 — the full CLI catalog plus category and selection state.
# See docs/JSON-CONTRACTS.md.
emit_catalog_json() {
  local cats=() sel=() c k
  while IFS= read -r c; do [[ -n "$c" ]] && cats+=("$c"); done < <(catalog_categories "$CLI_CATALOG")
  if [[ -f "$CLI_SELECTED" ]]; then
    while IFS= read -r k; do [[ -n "$k" ]] && sel+=("$k"); done \
      < <(sed 's/#.*//; s/[[:space:]]//g; /^$/d' "$CLI_SELECTED")
  fi
  printf '{"schema":"macstrap.catalog/v1","catalog":"cli","categories":%s,"selected":%s,"items":%s}\n' \
    "$(json_str_array ${cats[@]+"${cats[@]}"})" \
    "$(json_str_array ${sel[@]+"${sel[@]}"})" \
    "$(catalog_json "$CLI_CATALOG")"
}

# macstrap.plan/v1 — a resolved selection (keys only), install nothing.
emit_plan_json() {
  local ks=() k
  while IFS= read -r k; do [[ -n "$k" ]] && ks+=("$k"); done < <(printf '%s\n' "$1" | sed '/^$/d')
  printf '{"schema":"macstrap.plan/v1","catalog":"cli","keys":%s}\n' \
    "$(json_str_array ${ks[@]+"${ks[@]}"})"
}

# Print the catalog grouped by category, with descriptions.
list_catalog() {
  local cat
  echo "Optional CLIs (brew/cli.catalog):"
  for cat in $(catalog_categories "$CLI_CATALOG"); do
    printf '\n%s%s%s\n' "$b" "$cat" "$x"
    awk -F'|' -v c="$cat" '
      !/^[[:space:]]*#/ && NF >= 5 {
        n = split($4, a, ",")
        for (i = 1; i <= n; i++) { gsub(/^[ \t]+|[ \t]+$/, "", a[i]); if (a[i] == c) { printf "  %-14s %s\n", $1, $5; break } }
      }' "$CLI_CATALOG"
  done
  echo
  echo "Install:  macstrap cli <category>   |   macstrap cli tool1,tool2"
}

# Keep only tokens that are real catalog keys (drop typos before recording).
valid_keys() {
  local all
  all="$(catalog_keys "$CLI_CATALOG")"
  while IFS= read -r k; do
    [[ -z "$k" ]] && continue
    printf '%s\n' "$all" | grep -qxF "$k" && printf '%s\n' "$k"
  done
  return 0 # never fail the caller's `keys=$(...)` under set -e
}

# Merge newly chosen keys into brew/selected.cli (unique, sorted).
record_selection() {
  local tmp header
  header="# macstrap optional CLI selection. Managed by \`macstrap cli\`; replayed on install."
  tmp="$(mktemp)"
  {
    printf '%s\n' "$header"
    {
      [[ -f "$CLI_SELECTED" ]] && sed 's/#.*//; s/[[:space:]]//g; /^$/d' "$CLI_SELECTED"
      printf '%s\n' "$@"
    } | sed '/^$/d' | sort -u
  } >"$tmp"
  mv "$tmp" "$CLI_SELECTED"
}

# --- argument handling ---
# Pull flags out of the args; the rest form the selection.
JSON=0
DRY=0
args=()
for a in "$@"; do
  case "$a" in
    --verbose) export VERBOSE=1 ;;
    --json) JSON=1 ;;
    --dry-run | -n) DRY=1 ;;
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

# No selection given: JSON callers want the whole catalog; humans get the picker.
if [[ $# -eq 0 && $JSON -eq 1 ]]; then
  emit_catalog_json
  exit 0
fi

# Resolve the selection to a newline list of keys.
if [[ $# -eq 0 ]]; then
  selection="$(catalog_pick "$CLI_CATALOG" "Add project CLIs — space toggles, enter confirms." || true)"
  if [[ -z "$selection" ]]; then
    warn "Nothing selected (no interactive picker, or empty choice)."
    echo "  Browse the catalog:  macstrap cli --list"
    exit 0
  fi
else
  # Join args with commas so 'macstrap cli backend cloud' == 'backend,cloud'.
  selection="$(catalog_resolve "$CLI_CATALOG" "$(
    IFS=,
    echo "$*"
  )")"
fi

# Validate before doing anything.
keys="$(printf '%s\n' "$selection" | valid_keys)"
count="$(printf '%s\n' "$keys" | sed '/^$/d' | grep -c . || true)"

# JSON / dry-run: resolve only, never install.
if [[ $JSON -eq 1 ]]; then
  emit_plan_json "$keys"
  exit 0
fi
if [[ "${count:-0}" -eq 0 ]]; then
  warn "No known CLIs matched your selection."
  echo "  Browse the catalog:  macstrap cli --list"
  exit 1
fi
if [[ $DRY -eq 1 ]]; then
  log "Plan: $count project CLI(s) (dry run — nothing installed)"
  # shellcheck disable=SC2046  # keys are single words; word-splitting is intended
  catalog_describe "$CLI_CATALOG" $(printf '%s\n' "$keys" | sed '/^$/d')
  exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew is not installed. Run 'macstrap install' first."
  exit 1
fi

# Generate a Brewfile from the chosen keys and install.
gen="$DOTFILES_DIR/brew/generated"
mkdir -p "$gen"
{
  echo "# Generated by macstrap on $(date +%F). Do not edit."
  # shellcheck disable=SC2046  # keys are single words; word-splitting is intended
  catalog_emit "$CLI_CATALOG" $(printf '%s\n' "$keys" | sed '/^$/d')
} >"$gen/Brewfile.cli.local"

log "Installing $count project CLI(s)"
# Give each tool a reason to exist before the (quiet-by-default) install runs.
# shellcheck disable=SC2046  # keys are single words; word-splitting is intended
catalog_describe "$CLI_CATALOG" $(printf '%s\n' "$keys" | sed '/^$/d')
if run_logged "Installing $count project CLI(s)" brew bundle --file="$gen/Brewfile.cli.local"; then
  while IFS= read -r k; do [[ -n "$k" ]] && ok "$k"; done < <(printf '%s\n' "$keys" | sed '/^$/d')
else
  warn "Some CLIs failed to install (re-run with --verbose for details)."
fi

# Record the selection so a fresh machine replays it.
# shellcheck disable=SC2046  # keys are single words; word-splitting is intended
record_selection $(printf '%s\n' "$keys" | sed '/^$/d')
ok "Recorded in brew/selected.cli"
muted "Replayed automatically on your next Mac."
