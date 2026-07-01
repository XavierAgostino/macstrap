# macstrap interactive app picker demo. Render with:
#   vhs .github/assets/demo-apps.tape
# Safe: DRY_RUN=1 shows the picker and the resulting plan, installs nothing.

Output .github/assets/demo-apps.gif

Set Shell zsh
Set FontFamily "GeistMono Nerd Font"
Set FontSize 18
Set Width 1220
Set Height 760
Set Padding 28
Set TypingSpeed 55ms
Set Theme { "name": "Vesper", "background": "#101010", "foreground": "#ffffff", "cursor": "#acb1ab", "selection": "#988049", "black": "#101010", "red": "#f5a191", "green": "#90b99f", "yellow": "#e6b99d", "blue": "#aca1cf", "magenta": "#e29eca", "cyan": "#ea83a5", "white": "#a0a0a0", "brightBlack": "#7e7e7e", "brightRed": "#ff8080", "brightGreen": "#99ffe4", "brightYellow": "#ffc799", "brightBlue": "#b9aeda", "brightMagenta": "#ecaad6", "brightCyan": "#f591b2", "brightWhite": "#ffffff" }

Hide
Type "cd ~/Developer/workspaces/macstrap && clear" Enter
Show
Sleep 800ms

Type "macstrap install --apps --dry-run" Sleep 400ms Enter
Sleep 1600ms

Space Sleep 500ms
Down Sleep 300ms
Down Sleep 300ms
Space Sleep 500ms
Down Sleep 300ms
Down Sleep 300ms
Down Sleep 300ms
Space Sleep 500ms
Down Sleep 300ms
Space Sleep 600ms
Enter Sleep 2600ms
