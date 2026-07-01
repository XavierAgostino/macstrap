# shellcheck shell=bash
#
# macstrap catalog helpers. Shared by scripts/bootstrap.sh and scripts/cli.sh.
# Operates on the 5-field catalog schema used by brew/apps.catalog and
# brew/cli.catalog:
#
#   key|formula|kind|categories|description
#
# Pure helpers: sourcing this file defines functions and changes nothing else.

# Print keys from a catalog, optionally filtered to a single category.
#   catalog_keys <catalog-file> [category]
catalog_keys() {
  awk -F'|' -v cat="${2:-}" '
    !/^[[:space:]]*#/ && NF >= 5 && $1 != "" {
      if (cat == "") { print $1; next }
      n = split($4, a, ",")
      for (i = 1; i <= n; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", a[i])
        if (a[i] == cat) { print $1; next }
      }
    }' "$1"
}

# Print every category name in a catalog (unique, sorted), excluding "default".
#   catalog_categories <catalog-file>
catalog_categories() {
  awk -F'|' '
    !/^[[:space:]]*#/ && NF >= 5 {
      n = split($4, a, ",")
      for (i = 1; i <= n; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", a[i])
        if (a[i] != "" && a[i] != "default") print a[i]
      }
    }' "$1" | sort -u
}

# Succeed if <token> is a category in the catalog.
#   catalog_has_category <catalog-file> <token>
catalog_has_category() { catalog_categories "$1" | grep -qxF "$2"; }

# Emit Brewfile lines (brew "x" / cask "x") for the given keys.
#   catalog_emit <catalog-file> <key>...
catalog_emit() {
  local cf="$1"
  shift
  local key
  for key in "$@"; do
    [[ -z "$key" ]] && continue
    awk -F'|' -v k="$key" '
      !/^[[:space:]]*#/ && $1 == k { print $3 " \"" $2 "\""; exit }' "$cf"
  done
}

# Expand a comma-separated selection of categories and/or keys to a newline
# list of keys (categories expand to their members; unknown tokens pass through
# as literal keys).
#   catalog_resolve <catalog-file> <comma-separated-selection>
catalog_resolve() {
  local cf="$1" tok
  # NOTE: trailing newline is required so `read` yields the final token.
  printf '%s\n' "$2" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' |
    while IFS= read -r tok; do
      if catalog_has_category "$cf" "$tok"; then
        catalog_keys "$cf" "$tok"
      else
        printf '%s\n' "$tok"
      fi
    done | awk '!seen[$0]++' # de-dupe (a category + one of its members)
}

# Interactive multi-select picker (needs gum + a TTY). Prints chosen keys.
# Returns non-zero when no interactive picker is available so callers can fall
# back. Shows "key   description"; returns just the keys.
#   catalog_pick <catalog-file> <header>
catalog_pick() {
  command -v gum >/dev/null 2>&1 || brew install gum >/dev/null 2>&1 || true
  if command -v gum >/dev/null 2>&1 && [ -t 0 ]; then
    awk -F'|' '!/^[[:space:]]*#/ && NF >= 5 && $1 != "" { printf "%-16s %s\n", $1, $5 }' "$1" |
      gum choose --no-limit --height 20 --header "$2" |
      awk '{ print $1 }'
  else
    return 1
  fi
}
