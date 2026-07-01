#!/usr/bin/env bash
#
# CLI picker: "Can I add project tools later?" Scripted, non-mutating.
#
set -euo pipefail
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=demo/scripts/lib.sh
. "$DIR/lib.sh"

clear 2>/dev/null || true
title "macstrap cli" "Core stays lean — pull in project CLIs when you need them"
nap 0.8

prompt "macstrap cli backend,ai"
muted "Resolving groups: backend, ai"
nap 0.6

section "Installing 7 CLI(s):"
printf '  - supabase\n  - stripe\n  - redis\n  - grpcurl\n  - ollama\n  - llm\n  - aider\n'
nap 1
row_ok "supabase"
row_ok "stripe-cli"
row_ok "redis"
row_ok "grpcurl"
row_ok "ollama"
row_ok "llm"
row_ok "aider"
nap 0.9

section "Recorded selection in brew/selected.cli"
muted "  Replayed on a fresh Mac by the installer (macstrap install)."
nap 1

muted ""
prompt "macstrap cli --list"
printf '%sbackend%s\n' "$D_B" "$D_X"
printf '  supabase       Local Supabase, migrations, Edge Functions, types\n'
printf '  stripe         Stripe webhooks, events, and API testing\n'
printf '%scloud%s\n' "$D_B" "$D_X"
printf '  aws            AWS command-line interface\n'
printf '%skubernetes%s\n' "$D_B" "$D_X"
printf '  kubectl        Kubernetes command-line interface\n'
muted "  ... deploy · database · infra · security · ai · api · power-user"
nap 1
