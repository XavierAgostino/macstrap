#!/usr/bin/env bash
#
# macstrap security check. Read-only posture summary.
#
#   security-check.sh          human-readable summary
#   security-check.sh --json   machine-readable summary (macstrap.security/v1)
#
set -uo pipefail
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/workspaces/macstrap}"
# shellcheck source=scripts/lib/json.sh
. "$DOTFILES_DIR/scripts/lib/json.sh"

# security_checks — emit one "key<TAB>label<TAB>level<TAB>detail" line per check.
# level is ok | warn. Both the human report and --json render from these lines,
# so the two views can never drift.
security_checks() {
  # Secrets in the repo
  if ! command -v gitleaks >/dev/null 2>&1; then
    printf 'secrets\tSecrets (gitleaks)\twarn\tgitleaks not installed\n'
  elif gitleaks detect --source "$DOTFILES_DIR" --no-banner >/dev/null 2>&1; then
    printf 'secrets\tSecrets (gitleaks)\tok\tclean\n'
  else
    printf 'secrets\tSecrets (gitleaks)\twarn\tfindings (run: gitleaks detect)\n'
  fi

  # Commit signing
  if [[ "$(git config --global commit.gpgsign 2>/dev/null || true)" == "true" ]]; then
    printf 'commit_signing\tCommit signing\tok\ton\n'
  else
    printf 'commit_signing\tCommit signing\twarn\toff\n'
  fi

  # Pre-commit hook
  if [[ "$(git -C "$DOTFILES_DIR" config core.hooksPath 2>/dev/null || true)" == "scripts/hooks" ]]; then
    printf 'precommit_hook\tPre-commit hook\tok\tactive\n'
  else
    printf 'precommit_hook\tPre-commit hook\twarn\tnot set (run bootstrap)\n'
  fi

  # 1Password
  if ! command -v op >/dev/null 2>&1; then
    printf 'onepassword\t1Password CLI\twarn\tnot installed\n'
  elif op vault list >/dev/null 2>&1; then
    printf 'onepassword\t1Password CLI\tok\tsigned in\n'
  else
    printf 'onepassword\t1Password CLI\twarn\tlocked / signed out\n'
  fi

  # GitHub auth
  if gh auth status >/dev/null 2>&1; then
    printf 'github_auth\tGitHub auth\tok\tauthenticated\n'
  else
    printf 'github_auth\tGitHub auth\twarn\tnot authenticated\n'
  fi
}

# macstrap.security/v1 — see docs/JSON-CONTRACTS.md.
emit_json() {
  local checks="" overall=ok key label level detail
  while IFS=$'\t' read -r key label level detail; do
    [[ -z "$key" ]] && continue
    [[ "$level" != "ok" ]] && overall=warn
    checks+="${checks:+,}{\"key\":$(json_str "$key"),\"label\":$(json_str "$label"),\"level\":$(json_str "$level"),\"detail\":$(json_str "$detail")}"
  done < <(security_checks)
  printf '{"schema":"macstrap.security/v1","overall":%s,"checks":[%s]}\n' \
    "$(json_str "$overall")" "$checks"
}

if [[ "${1:-}" == "--json" ]]; then
  emit_json
  exit 0
fi

# --- human-readable report ---
g=$'\033[32m'
y=$'\033[33m'
x=$'\033[0m'
row() { printf '  %-24s %s%s%s\n' "$1" "$2" "$3" "$x"; }

echo "== macstrap security check =="
echo
while IFS=$'\t' read -r key label level detail; do
  [[ -z "$key" ]] && continue
  if [[ "$level" == "ok" ]]; then row "$label:" "$g" "$detail"; else row "$label:" "$y" "$detail"; fi
done < <(security_checks)
