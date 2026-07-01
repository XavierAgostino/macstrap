# macstrap TUI demo — regenerate with:  vhs demo/tapes/tui.tape
#
# Records the REAL Bubble Tea TUI (cmd/macstrap) navigating its read-only
# screens — dashboard, Doctor, the app picker, Report, Security. Non-mutating:
# it never presses enter on a picker, so nothing is ever installed.
#
# The Hide block builds the binary to a temp dir and puts it first on PATH, so
# `macstrap` resolves to the Go TUI (not the bash bin/macstrap fallback).

Output .github/assets/demo-tui.gif

Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 760
Set Padding 24
Set Theme "Catppuccin Mocha"

Hide
Type "export MACSTRAP_DIR=$PWD DOTFILES_DIR=$PWD" Enter
Type "mkdir -p /tmp/macstrap-demo && go build -o /tmp/macstrap-demo/macstrap ./cmd/macstrap" Enter
Sleep 10s
Type "export PATH=/tmp/macstrap-demo:/opt/homebrew/bin:$PATH" Enter
Ctrl+L
Show

# Dashboard (cursor starts on Doctor).
Type "macstrap" Enter
Sleep 3s

# Doctor — run the health check (shells out; hold for results), then back.
Enter
Sleep 7s
Escape
Sleep 1s

# Apps — open the multi-select and toggle a couple (never confirm).
Down
Enter
Sleep 2s
Space
Down
Down
Space
Sleep 1500ms
Escape
Sleep 800ms

# Report — what macstrap manages.
Down
Down
Enter
Sleep 4s
Escape
Sleep 1s

# Security — posture summary.
Down
Enter
Sleep 4s
Escape
Sleep 1s

# Quit.
Type "q"
Sleep 1s
