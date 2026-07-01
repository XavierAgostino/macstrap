#!/usr/bin/env bash
#
# Doctor: "How do I know my machine is healthy?" Scripted, non-mutating.
# Mirrors the real grouped layout of scripts/dev-doctor.sh.
#
set -euo pipefail
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=demo/scripts/lib.sh
. "$DIR/lib.sh"

clear 2>/dev/null || true
title "macstrap doctor" "One scannable health check across your whole setup"
nap 0.8

prompt "macstrap doctor"

section "System"
row_val "macOS" "15.5"
row_val "Apple Silicon" "yes"
row_val "Shell" "zsh"

section "Core"
row_ok "Homebrew"
row_ok "chezmoi"
row_ok "mise"
row_ok "GitHub CLI"

section "Runtimes"
row_ok "Node"
row_ok "pnpm"
row_ok "Python / uv"

section "Security"
row_ok "1Password"
row_ok "Git signing"
row_ok "Gitleaks hook"

section "Next"
row_val "macstrap cli backend" "Add Supabase, Stripe, Postgres tools"
row_val "macstrap apps" "Pick optional GUI apps"
nap 1.2
