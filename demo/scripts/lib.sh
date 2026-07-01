# shellcheck shell=bash
#
# Shared helpers for macstrap demo scripts.
#
# These walkthroughs are SCRIPTED, DETERMINISTIC, and NON-MUTATING: they print a
# branded product tour and never install, clone, or change anything. That is what
# makes the recorded GIFs clean and repeatable (see docs/DEMOS.md).
#
# Set DEMO_SPEED=0 to remove all pauses (used by tests / quick checks).

# Colors — the Vesper language from docs/COLORS.md, matching scripts/bootstrap.sh.
D_B=$'\033[1;34m'       # blue   — section arrow (==>)
D_G=$'\033[32m'         # green  — ok / healthy
D_MUT=$'\033[90m'       # muted  — secondary text
D_ACC=$'\033[38;5;175m' # pink   — the one prompt accent
D_X=$'\033[0m'

DEMO_SPEED="${DEMO_SPEED:-1}"

nap() { [ "$DEMO_SPEED" = "0" ] || sleep "$1"; }

# A typed-looking shell prompt line.
prompt() {
  printf '%s❯%s %s\n' "$D_ACC" "$D_X" "$1"
  nap 0.7
}

title() {
  printf '%s%s%s\n' "$D_B" "$1" "$D_X"
  printf '%s%s%s\n' "$D_MUT" "$2" "$D_X"
}

section() { printf '\n%s==>%s %s\n' "$D_B" "$D_X" "$1"; }
row_ok() { printf '  %-15s %sok%s\n' "$1" "$D_G" "$D_X"; }
row_val() { printf '  %-15s %s\n' "$1" "$2"; }
muted() { printf '%s%s%s\n' "$D_MUT" "$1" "$D_X"; }
