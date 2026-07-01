#!/usr/bin/env bash
#
# macstrap dev-doctor. Diagnose the machine, or emit machine-readable status.
#
#   dev-doctor.sh            human-readable report
#   dev-doctor.sh --json     machine-readable status (agents / CI)
#   dev-doctor.sh --fix      apply safe, non-destructive repairs, then report
#
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/workspaces/macstrap}"
# Resolve mise-managed runtimes (node, etc.) even in this non-interactive shell.
[[ -d "$HOME/.local/share/mise/shims" ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"

# --- structured checks: emit "key<TAB>status" lines ---
run_checks() {
  command -v brew >/dev/null 2>&1 && printf 'homebrew\tok\n' || printf 'homebrew\tmissing\n'
  if ! command -v chezmoi >/dev/null 2>&1; then
    printf 'chezmoi\tmissing\n'
  elif chezmoi verify >/dev/null 2>&1; then
    printf 'chezmoi\tok\n'
  else printf 'chezmoi\twarning\n'; fi
  command -v mise >/dev/null 2>&1 && printf 'mise\tok\n' || printf 'mise\tmissing\n'
  command -v node >/dev/null 2>&1 && printf 'node\tok\n' || printf 'node\tmissing\n'
  [[ "$(git config --global commit.gpgsign 2>/dev/null || true)" == "true" ]] &&
    printf 'git_signing\tok\n' || printf 'git_signing\toff\n'
  if ! command -v op >/dev/null 2>&1; then
    printf 'onepassword\tmissing\n'
  elif op vault list >/dev/null 2>&1; then
    printf 'onepassword\tok\n'
  else printf 'onepassword\tlocked\n'; fi
  command -v gitleaks >/dev/null 2>&1 && printf 'gitleaks\tok\n' || printf 'gitleaks\tmissing\n'
}

emit_json() {
  run_checks | awk -F'\t' 'BEGIN{print "{"} {printf "%s  \"%s\": \"%s\"", (NR>1?",\n":""), $1,$2} END{print "\n}"}'
}

safe_fix() {
  echo "Applying safe fixes (non-destructive)..."
  # Re-enable the secret-scan git hook.
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" config core.hooksPath scripts/hooks 2>/dev/null && echo "  set core.hooksPath"
  fi
  # Re-link the macstrap CLI onto PATH if missing.
  if [[ -f "$DOTFILES_DIR/bin/macstrap" && ! -e "$HOME/.local/bin/macstrap" ]]; then
    mkdir -p "$HOME/.local/bin" && ln -sf "$DOTFILES_DIR/bin/macstrap" "$HOME/.local/bin/macstrap" && echo "  linked macstrap CLI"
  fi
  # Ensure runtimes are installed.
  if command -v mise >/dev/null 2>&1; then mise install >/dev/null 2>&1 && echo "  ran mise install"; fi
  # Reconcile core Homebrew packages (idempotent; installs anything missing).
  if command -v brew >/dev/null 2>&1 && [[ -f "$DOTFILES_DIR/brew/Brewfile.core" ]]; then
    brew bundle --file="$DOTFILES_DIR/brew/Brewfile.core" >/dev/null 2>&1 && echo "  reconciled core packages"
  fi
  echo "  signing / 1Password / drift issues are advisory only (see docs/work-separation.md, docs/TROUBLESHOOTING.md)"
  echo
}

# --- argument handling ---
case "${1:-}" in
  --json)
    emit_json
    exit 0
    ;;
  --fix) safe_fix ;;
  "" | --report) ;;
  *)
    echo "usage: dev-doctor.sh [--json|--fix]" >&2
    exit 2
    ;;
esac

# --- human-readable report ---
echo "== macstrap dev-doctor =="
echo "Date: $(date)"
echo

# Grouped, scannable layout. Statuses come from the same run_checks used by --json.
g=$'\033[32m'
y=$'\033[33m'
r=$'\033[31m'
x=$'\033[0m'
CHECKS="$(run_checks)"
status() { printf '%s\n' "$CHECKS" | awk -F'\t' -v k="$1" '$1 == k { print $2; exit }'; }
paint() {
  case "$1" in
    ok) printf '%s%s%s' "$g" "$1" "$x" ;;
    warning | locked | off) printf '%s%s%s' "$y" "$1" "$x" ;;
    *) printf '%s%s%s' "$r" "$1" "$x" ;;
  esac
}
check_line() { printf '  %-15s %s\n' "$1" "$(paint "$(status "$2")")"; }
ver_line() {
  local out
  # shellcheck disable=SC2086
  out="$($1 2>/dev/null | sed -n '1p')"
  printf '  %-15s %s\n' "$2" "${out:-missing}"
}

echo "-- System --"
printf '  %-15s %s\n' "macOS" "$(sw_vers -productVersion 2>/dev/null || echo unknown)"
printf '  %-15s %s\n' "Apple Silicon" "$([[ "$(uname -m)" == "arm64" ]] && echo yes || echo no)"
printf '  %-15s %s\n' "Shell" "${SHELL:-unknown}"
echo

echo "-- Core --"
check_line "Homebrew" homebrew
check_line "chezmoi" chezmoi
check_line "mise" mise
if command -v gh >/dev/null 2>&1; then gh_stat=ok; else gh_stat=missing; fi
printf '  %-15s %s\n' "GitHub CLI" "$(paint "$gh_stat")"
echo

echo "-- Runtimes --"
ver_line "node --version" "Node"
ver_line "pnpm --version" "pnpm"
ver_line "uv --version" "Python / uv"
echo

echo "-- Security --"
check_line "1Password" onepassword
printf '  %-15s %s\n' "Git signing" "$(paint "$(status git_signing)")"
check_line "Gitleaks hook" gitleaks
echo

echo "-- chezmoi --"
if command -v chezmoi >/dev/null 2>&1; then
  echo "  source:  $(chezmoi source-path 2>/dev/null)"
  echo "  profile: $(chezmoi execute-template '{{ .profile }}' 2>/dev/null)"
  chezmoi verify >/dev/null 2>&1 && echo "  state:   clean (live matches source)" ||
    echo "  state:   drift (run 'chezmoi diff')"
fi
echo

echo "-- Next --"
printf '  %-22s %s\n' "macstrap cli backend" "Add Supabase, Stripe, Postgres tools"
printf '  %-22s %s\n' "macstrap apps" "Pick optional GUI apps"
