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
nap 0.4

section "Installing 7 project CLI(s)"
desc_row "supabase" "Local Supabase, migrations, Edge Functions, types"
desc_row "stripe" "Stripe webhooks, events, and API testing"
desc_row "redis" "Redis server and redis-cli"
desc_row "grpcurl" "curl-like CLI for gRPC"
desc_row "ollama" "Run local LLMs"
desc_row "llm" "Simon Willison's LLM CLI"
desc_row "aider" "AI pair programming in the terminal"
nap 1
for t in supabase stripe redis grpcurl ollama llm aider; do ok_line "$t"; done
nap 0.5
ok_line "Recorded in brew/selected.cli"
muted "Replayed automatically on your next Mac."
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
