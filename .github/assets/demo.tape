# macstrap demo. Render with:  vhs .github/assets/demo.tape
# Uses the Vesper theme (matching Ghostty) and Geist Mono Nerd Font.
# Install renderer: brew install vhs

Output .github/assets/demo.gif

Set Shell zsh
Set FontFamily "GeistMono Nerd Font"
Set FontSize 18
Set Width 1320
Set Height 820
Set Padding 28
Set TypingSpeed 55ms
Set Theme { "name": "Vesper", "background": "#101010", "foreground": "#ffffff", "cursor": "#acb1ab", "selection": "#988049", "black": "#101010", "red": "#f5a191", "green": "#90b99f", "yellow": "#e6b99d", "blue": "#aca1cf", "magenta": "#e29eca", "cyan": "#ea83a5", "white": "#a0a0a0", "brightBlack": "#7e7e7e", "brightRed": "#ff8080", "brightGreen": "#99ffe4", "brightYellow": "#ffc799", "brightBlue": "#b9aeda", "brightMagenta": "#ecaad6", "brightCyan": "#f591b2", "brightWhite": "#ffffff" }
Set Margin 44
Set MarginFill "#1b1622"
Set BorderRadius 12
Set WindowBar Colorful

Hide
Type "cd ~/Developer/workspaces/macstrap && clear" Enter
Show
Sleep 900ms

Type "eza --icons --git" Sleep 400ms Enter
Sleep 2200ms

Type "macstrap install --dry-run" Sleep 400ms Enter
Sleep 3200ms

Type "macstrap doctor --json | jq" Sleep 400ms Enter
Sleep 3200ms
