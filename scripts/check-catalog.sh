#!/usr/bin/env bash
#
# Catalog hygiene. Fails if:
#   - a catalog row is malformed (not 5 fields, empty key/formula, bad kind)
#   - a catalog has duplicate keys
#   - an optional CLI duplicates a package already in Brewfile.core
#     (the catalog is for DISCOVERY; core is installed for everyone)
#
# With --online (requires Homebrew; run on macOS CI): also verify that every
# formula/cask actually exists in Homebrew, catching entries like `terraform`
# that were removed from homebrew-core.
#
set -euo pipefail

ONLINE=0
[[ "${1:-}" == "--online" ]] && ONLINE=1

ROOT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE="$ROOT_DIR/brew/Brewfile.core"
CATALOGS=("$ROOT_DIR/brew/apps.catalog" "$ROOT_DIR/brew/cli.catalog")
fail=0

err() {
  echo "  FAIL: $*" >&2
  fail=1
}

# 1. Row shape + duplicate keys, per catalog.
for cat in "${CATALOGS[@]}"; do
  echo "Checking $(basename "$cat")..."
  awk -F'|' -v file="$(basename "$cat")" '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    {
      if (NF != 5) { print "  FAIL: " file ":" NR ": expected 5 fields, got " NF " -> " $0; bad=1; next }
      if ($1 == "" || $2 == "") { print "  FAIL: " file ":" NR ": empty key or formula"; bad=1 }
      if ($3 != "brew" && $3 != "cask") { print "  FAIL: " file ":" NR ": kind must be brew|cask, got \"" $3 "\""; bad=1 }
      if (seen[$1]++) { print "  FAIL: " file ": duplicate key \"" $1 "\""; bad=1 }
    }
    END { exit bad }
  ' "$cat" || fail=1
done

# 2. No optional CLI may duplicate a Brewfile.core package.
core_formulas="$(awk -F'"' '/^[[:space:]]*(brew|cask) "/ { print $2 }' "$CORE" | sort -u)"
cli_formulas="$(awk -F'|' '!/^[[:space:]]*#/ && NF==5 { print $2 }' "$ROOT_DIR/brew/cli.catalog" | sort -u)"
dupes="$(comm -12 <(printf '%s\n' "$core_formulas") <(printf '%s\n' "$cli_formulas"))"
if [[ -n "$dupes" ]]; then
  while IFS= read -r d; do
    [[ -n "$d" ]] && err "cli.catalog lists \"$d\", already in Brewfile.core"
  done <<<"$dupes"
fi

# 3. (--online) every formula/cask must resolve in Homebrew.
if [[ "$ONLINE" -eq 1 ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    err "--online requires Homebrew, but brew was not found"
  else
    for cat in "${CATALOGS[@]}"; do
      echo "Resolving formulas in $(basename "$cat")..."
      # shellcheck disable=SC2094  # $cat is only read; the >/dev/null writes are unrelated
      while IFS='|' read -r key formula kind _; do
        case "$key" in \#* | "") continue ;; esac
        [[ -z "$formula" ]] && continue
        if [[ "$kind" == "cask" ]]; then
          brew info --cask "$formula" >/dev/null 2>&1 || err "$(basename "$cat"): cask \"$formula\" (key $key) does not resolve in Homebrew"
        else
          brew info --formula "$formula" >/dev/null 2>&1 || err "$(basename "$cat"): formula \"$formula\" (key $key) does not resolve in Homebrew"
        fi
      done <"$cat"
    done
  fi
fi

if [[ "$fail" -ne 0 ]]; then
  echo "Catalog hygiene: FAILED" >&2
  exit 1
fi
echo "Catalog hygiene: OK"
