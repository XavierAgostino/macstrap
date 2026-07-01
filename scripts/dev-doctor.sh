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
  command -v brew  >/dev/null 2>&1 && printf 'homebrew\tok\n'   || printf 'homebrew\tmissing\n'
  if   ! command -v chezmoi >/dev/null 2>&1; then printf 'chezmoi\tmissing\n'
  elif chezmoi verify >/dev/null 2>&1;        then printf 'chezmoi\tok\n'
  else printf 'chezmoi\twarning\n'; fi
  command -v mise >/dev/null 2>&1 && printf 'mise\tok\n' || printf 'mise\tmissing\n'
  command -v node >/dev/null 2>&1 && printf 'node\tok\n' || printf 'node\tmissing\n'
  [[ "$(git config --global commit.gpgsign 2>/dev/null || true)" == "true" ]] \
    && printf 'git_signing\tok\n' || printf 'git_signing\toff\n'
  if   ! command -v op >/dev/null 2>&1;  then printf 'onepassword\tmissing\n'
  elif op vault list >/dev/null 2>&1;    then printf 'onepassword\tok\n'
  else printf 'onepassword\tlocked\n'; fi
  command -v gitleaks >/dev/null 2>&1 && printf 'gitleaks\tok\n' || printf 'gitleaks\tmissing\n'
}

emit_json() {
  run_checks | awk -F'\t' 'BEGIN{print "{"} {printf "%s  \"%s\": \"%s\"", (NR>1?",\n":""), $1,$2} END{print "\n}"}'
}

safe_fix() {
  echo "Applying safe fixes (non-destructive)..."
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" config core.hooksPath scripts/hooks 2>/dev/null && echo "  set core.hooksPath"
  fi
  if command -v mise >/dev/null 2>&1; then mise install >/dev/null 2>&1 && echo "  ran mise install"; fi
  echo "  signing / 1Password / drift issues are advisory only (see docs/work-separation.md, docs/TROUBLESHOOTING.md)"
  echo
}

# --- argument handling ---
case "${1:-}" in
  --json) emit_json; exit 0 ;;
  --fix)  safe_fix ;;
  ""|--report) ;;
  *) echo "usage: dev-doctor.sh [--json|--fix]" >&2; exit 2 ;;
esac

# --- human-readable report ---
echo "== macstrap dev-doctor =="
echo "Date: $(date)"
echo

echo "-- Checks --"
run_checks | while IFS=$'\t' read -r k v; do
  case "$v" in
    ok)       c=$'\033[32m' ;;
    warning|locked|off) c=$'\033[33m' ;;
    *)        c=$'\033[31m' ;;
  esac
  printf '  %-13s %s%s\033[0m\n' "$k" "$c" "$v"
done
echo

echo "-- System --"
sw_vers; echo "arch: $(uname -m)"; echo "shell: ${SHELL:-unknown}"
echo

echo "-- Versions --"
for c in "chezmoi --version" "mise --version" "node --version" "pnpm --version" \
         "uv --version" "git --version"; do
  # shellcheck disable=SC2086
  $c 2>/dev/null | sed -n '1p' || true
done
echo

echo "-- mise tools --"
mise ls 2>/dev/null || echo "mise not active"
echo

echo "-- chezmoi --"
if command -v chezmoi >/dev/null 2>&1; then
  echo "source:  $(chezmoi source-path 2>/dev/null)"
  echo "profile: $(chezmoi execute-template '{{ .profile }}' 2>/dev/null)"
  chezmoi verify >/dev/null 2>&1 && echo "state:   clean (live matches source)" \
    || echo "state:   drift (run 'chezmoi diff')"
fi
