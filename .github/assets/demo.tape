# macstrap demo — render with:  vhs .github/assets/demo.tape
# Produces .github/assets/demo.gif  (install: brew install vhs)

Output .github/assets/demo.gif

Set Shell zsh
Set FontFamily "JetBrainsMono Nerd Font"   # nerd font so eza icons render
Set FontSize 18
Set Width 1200
Set Height 700
Set Padding 24
Set Theme "Catppuccin Mocha"

Hide
Type "clear" Enter
Show

Sleep 700ms
Type "eza --icons --git --tree --level=1"  Sleep 600ms  Enter
Sleep 2s
Type "mise ls"  Sleep 600ms  Enter
Sleep 2s
Type "git status"  Sleep 600ms  Enter
Sleep 2s
Type "brewadd --help 2>/dev/null || echo 'brewadd <pkg>  ·  dotsync  ·  doctor'"  Sleep 600ms  Enter
Sleep 2500ms
