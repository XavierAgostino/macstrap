# macstrap doctor demo — regenerate with:  vhs demo/tapes/doctor.tape
# Drives demo/scripts/04-doctor.sh (scripted, non-mutating).

Output .github/assets/demo-doctor.gif

Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 640
Set Padding 24
Set Theme "Catppuccin Mocha"

Hide
Type "export PATH=$PWD/bin:$PATH" Enter
Ctrl+L
Show

Type "macstrap demo doctor" Enter
Sleep 6s
