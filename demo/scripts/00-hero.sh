#!/usr/bin/env bash
#
# Hero walkthrough: "What is macstrap?" in one screen — preview, pick, verify.
# Scripted and non-mutating (see docs/DEMOS.md).
#
set -euo pipefail
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=demo/scripts/lib.sh
. "$DIR/lib.sh"

clear 2>/dev/null || true
title "macstrap" "Bootstrap a modern macOS dev environment in one command"
nap 0.8

# 1. Preview — trust it before you run it.
prompt "macstrap install --dry-run"
section "DRY RUN, no changes will be made. Planned actions:"
row_val "Mode:" "default"
row_val "Homebrew:" "installed"
row_val "chezmoi:" "installed -> init + apply"
row_val "Core packages:" "30 from Brewfile.core"
row_val "Apps:" "13 selected"
row_val "Project CLIs:" "none yet"
row_val "Profile:" "choose during setup"
nap 1.2

# 2. Pick — only what you want.
prompt "macstrap apps"
muted "Pick the GUI apps you want — space toggles, enter confirms."
printf '  %s◉%s Cursor      %s◉%s Claude Code   %s◉%s Ghostty\n' "$D_G" "$D_X" "$D_G" "$D_X" "$D_G" "$D_X"
printf '  %s◉%s Raycast     %s◉%s OrbStack      %s◯%s Figma\n' "$D_G" "$D_X" "$D_G" "$D_X" "$D_MUT" "$D_X"
printf '  %s◯%s Notion      %s◯%s Spotify\n' "$D_MUT" "$D_X" "$D_MUT" "$D_X"
nap 1.2

# 3. Verify — know your Mac is healthy.
prompt "macstrap doctor"
section "macstrap dev-doctor"
row_ok "Homebrew"
row_ok "chezmoi"
row_ok "mise"
row_ok "Node"
row_ok "Git signing"
row_ok "1Password"
row_ok "Gitleaks hook"
nap 0.8
printf '\n  %sYour Mac is ready.%s\n' "$D_G" "$D_X"
nap 1
