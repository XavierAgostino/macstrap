#!/usr/bin/env bash
#
# App picker: "Can I install only what I want?" Scripted, non-mutating.
#
set -euo pipefail
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=demo/scripts/lib.sh
. "$DIR/lib.sh"

clear 2>/dev/null || true
title "macstrap apps" "Pick exactly the GUI apps you want — the rest stay off"
nap 0.8

prompt "macstrap apps"
muted "Pick the GUI apps you want — space toggles, enter confirms."
printf '  %s◉%s cursor            AI-native editor\n' "$D_G" "$D_X"
printf '  %s◉%s claude-code       terminal AI coding agent\n' "$D_G" "$D_X"
printf '  %s◉%s ghostty           GPU-accelerated terminal\n' "$D_G" "$D_X"
printf '  %s◉%s raycast           launcher / clipboard / windows\n' "$D_G" "$D_X"
printf '  %s◉%s orbstack          Docker / Linux VMs\n' "$D_G" "$D_X"
printf '  %s◯%s figma             design\n' "$D_MUT" "$D_X"
printf '  %s◯%s notion            docs and wiki\n' "$D_MUT" "$D_X"
printf '  %s◯%s spotify           music\n' "$D_MUT" "$D_X"
nap 1.4

section "Installing 5 app(s)"
row_ok "cursor"
row_ok "claude-code"
row_ok "ghostty"
row_ok "raycast"
row_ok "orbstack"
nap 1

muted ""
muted "Tip: use  macstrap apps design  to install a curated group."
nap 1
