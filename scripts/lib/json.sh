# shellcheck shell=bash
#
# macstrap JSON helpers — emit valid JSON from shell without depending on jq at
# runtime (doctor/report/security can run before core packages are installed,
# and agents/CI parse their output). Pure: sourcing this file only defines
# functions. The Go TUI and `jq` consume what these produce; see
# docs/JSON-CONTRACTS.md for the schemas.

# json_str <value> — print a JSON string literal (with surrounding quotes),
# escaping per RFC 8259. Handles the characters our controlled data can contain
# (backslash, quote, tab, CR, LF); anything else is passed through.
json_str() {
  local s=${1-}
  s=${s//\\/\\\\} # backslash first, so later escapes are not re-escaped
  s=${s//\"/\\\"}
  s=${s//$'\t'/\\t}
  s=${s//$'\r'/\\r}
  s=${s//$'\n'/\\n}
  printf '"%s"' "$s"
}

# json_str_array <item>... — print a JSON array of strings: ["a","b"].
# Empty arguments are skipped (our keys/categories are always non-empty).
json_str_array() {
  local out="" a
  for a in "$@"; do
    [[ -z "$a" ]] && continue
    out+="${out:+,}$(json_str "$a")"
  done
  printf '[%s]' "$out"
}
