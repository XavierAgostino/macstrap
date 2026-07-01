# macstrap hero demo — regenerate with:  vhs demo/tapes/hero.tape
# Requires: brew bundle --file=brew/Brewfile.dev  (installs vhs)
# Drives the scripted, non-mutating walkthrough in demo/scripts/00-hero.sh.

Output .github/assets/demo.gif

Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 760
Set Padding 24
Set Theme "Catppuccin Mocha"
Set PlaybackSpeed 1.0

Hide
Type "export PATH=$PWD/bin:$PATH" Enter
Ctrl+L
Show

Type "macstrap demo hero" Enter
Sleep 12s
