# shellcheck shell=bash
#
# macstrap shared UI helpers — one calm output style across the installer and
# CLIs. Colored text labels (no emoji), matching docs/COLORS.md. Sourcing this
# file only defines vars/functions; it changes nothing else.
#
# Long, noisy steps run through `run_logged`: concise by default (output goes to
# a per-step log, shown only on failure) or streamed live with VERBOSE=1
# (`macstrap install --verbose`). Interactive commands must NOT use run_logged —
# a captured prompt would hang.

# Colors (Vesper).
b=$'\033[1;34m' # blue  — section arrow (==>)
g=$'\033[32m'   # green — ok
y=$'\033[33m'   # amber — warn
r=$'\033[31m'   # red   — fail
mut=$'\033[90m' # muted — secondary detail
x=$'\033[0m'

VERBOSE="${VERBOSE:-0}"
# One log directory per run; a step writes "<slug>.log" here in concise mode.
UI_LOG_DIR="${UI_LOG_DIR:-${TMPDIR:-/tmp}/macstrap-logs}"

log() { printf '\n%s==>%s %s\n' "$b" "$x" "$*"; }
ok() { printf '  %sok%s   %s\n' "$g" "$x" "$*"; }

# Step-based progress: honest phase counter, no fake percentages.
# Call ui_phase_total <N> once, then ui_phase "Label" as each phase begins.
UI_PHASE_TOTAL="${UI_PHASE_TOTAL:-0}"
UI_PHASE_N=0
ui_phase_total() { UI_PHASE_TOTAL="$1"; }
ui_phase() {
  UI_PHASE_N=$((UI_PHASE_N + 1))
  printf '\n%s[%d/%d]%s %s\n' "$b" "$UI_PHASE_N" "$UI_PHASE_TOTAL" "$x" "$*"
}
warn() { printf '  %swarn%s %s\n' "$y" "$x" "$*"; }
skip() { printf '  %sskip%s %s\n' "$mut" "$x" "$*"; }
muted() { printf '  %s%s%s\n' "$mut" "$*" "$x"; }
die() {
  printf '  %sfail%s %s\n' "$r" "$x" "$*"
  exit 1
}

# A filesystem-safe slug from a step description (for the log filename).
slugify() { printf '%s' "$1" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-'; }

# run_logged <description> <cmd...> — run a long, NON-INTERACTIVE command.
# Streams output when VERBOSE=1, when stdout is not a TTY (e.g. CI), or when gum
# is unavailable. Otherwise shows a gum spinner, captures output to a log, and
# on failure prints where to find it. Returns the command's exit status.
run_logged() {
  local desc="$1"
  shift
  if [[ "$VERBOSE" == "1" ]] || [[ ! -t 1 ]] || ! command -v gum >/dev/null 2>&1; then
    "$@"
    return $?
  fi
  mkdir -p "$UI_LOG_DIR"
  local logfile st=0
  logfile="$UI_LOG_DIR/$(slugify "$desc").log"
  # The single-quoted script is the inner shell's program (log path is $1); it
  # must NOT expand in this outer shell, so SC2016 is intentional here.
  # shellcheck disable=SC2016
  gum spin --spinner dot --title "$desc…" -- \
    bash -c 'exec >"$1" 2>&1; shift; "$@"' macstrap "$logfile" "$@" || st=$?
  if [[ $st -ne 0 ]]; then
    muted "log:    $logfile"
    muted "detail: re-run with --verbose"
  fi
  return $st
}
