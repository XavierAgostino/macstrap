# macstrap TUI demo — regenerate with:  vhs demo/tapes/tui.tape
#
# Records the REAL Bubble Tea TUI (cmd/macstrap) navigating its read-only
# screens — dashboard, Doctor, the app picker (with / search), Report,
# Security, Logs, and the Install plan preview. Non-mutating: pickers are
# never confirmed and Install only shows the --dry-run plan, so nothing is
# ever installed.
#
# The Hide block builds the binary to a temp dir and puts it first on PATH, so
# `macstrap` resolves to the Go TUI (not the bash bin/macstrap fallback). It also
# seeds a couple of fake step logs into UI_LOG_DIR so the Logs screen has content
# (a fresh clone has none yet).

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
Type "export UI_LOG_DIR=/tmp/macstrap-demo-logs && mkdir -p $UI_LOG_DIR" Enter
Type "printf 'Warning: Treating cursor as a cask.\n==> Downloading cursor\n==> Installing Cask cursor\ncursor was successfully installed!\n' > $UI_LOG_DIR/install-homebrew-casks.log" Enter
Type "printf 'Cloning dotfiles…\nApplying chezmoi state\nDone.\n' > $UI_LOG_DIR/apply-dotfiles.log" Enter
Ctrl+L
Show

# Dashboard — status pane fills in as the report + background doctor land.
Type "macstrap" Enter
Sleep 6s

# Doctor — the background run is cached, so results show instantly.
Enter
Sleep 4s
Escape
Sleep 1s

# Apps — multi-select with preview pane; toggle a couple, then / search.
Down
Enter
Sleep 2500ms
Space
Down
Down
Space
Sleep 1500ms
Type "/"
Sleep 500ms
Type "brow"
Sleep 2s
Escape
Sleep 1200ms
Escape
Sleep 800ms

# Report — what macstrap manages.
Down
Down
Enter
Sleep 4s
Escape
Sleep 1s

# Security — posture summary with suggested action.
Down
Enter
Sleep 4s
Escape
Sleep 1s

# Logs — browse the captured step logs, open one, then back out.
Down
Enter
Sleep 2s
Enter
Sleep 2500ms
Escape
Sleep 1s
Escape
Sleep 800ms

# Install — stream the dry-run plan (read-only; never confirm).
Down
Enter
Sleep 4s
Escape
Sleep 1s

# Quit.
Type "q"
Sleep 1s
