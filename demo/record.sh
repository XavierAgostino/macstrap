#!/usr/bin/env bash
#
# Regenerate macstrap demo GIFs from the .tape files with VHS.
#
#   ./demo/record.sh            record all tapes
#   ./demo/record.sh hero       record a single demo (hero|apps|cli|doctor|tui)
#
# Requires VHS:  brew bundle --file=brew/Brewfile.dev
# The tapes drive the scripted, non-mutating walkthroughs in demo/scripts/ and
# write GIFs into .github/assets/. See docs/DEMOS.md.
#
set -euo pipefail

ROOT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAPES_DIR="$ROOT_DIR/demo/tapes"

if ! command -v vhs >/dev/null 2>&1; then
  echo "vhs not found. Install it with: brew bundle --file=brew/Brewfile.dev" >&2
  exit 1
fi

record() {
  local tape="$TAPES_DIR/$1.tape"
  [[ -f "$tape" ]] || {
    echo "No such tape: $1 (expected $tape)" >&2
    exit 2
  }
  echo "==> Recording $1"
  (cd "$ROOT_DIR" && vhs "$tape")
}

if [[ $# -eq 0 || "${1:-}" == "all" ]]; then
  for t in hero apps cli doctor tui; do record "$t"; done
else
  for t in "$@"; do record "$t"; done
fi

echo "Done. GIFs written to .github/assets/"
