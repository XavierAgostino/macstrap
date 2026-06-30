# ~/.config/zsh/aliases.zsh — shell aliases. Managed by chezmoi.

# --- Modern CLI replacements ---
alias ls="eza --icons --git"
alias ll="eza -l --icons --git"
alias la="eza -la --icons --git"
alias lt="eza --tree --level=2 --icons"
alias cat="bat --style=plain"
alias catp="bat --style=plain --paging=never"
alias grep="rg"           # NOTE: interactive only; scripts still use /usr/bin/grep

# --- Python (prefer Homebrew python3 runtime) ---
alias python="python3"
alias pip="python3 -m pip"

# --- pnpm shortcuts ---
alias p="pnpm"
alias pi="pnpm install"
alias pa="pnpm add"
alias pd="pnpm dev"
alias pb="pnpm build"
alias px="pnpm dlx"

# --- git (curated; OMZ git-plugin replacement) ---
alias gs="git status -sb"
alias ga="git add"
alias gc="git commit"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias glog="git log --oneline --graph --decorate -20"

# --- Maintenance / navigation ---
alias doctor='bash "$HOME/Developer/workspaces/macstrap/scripts/dev-doctor.sh"'
alias dotfiles='cd "$HOME/Developer/workspaces/macstrap"'
alias brewfile-snapshot='brew bundle dump --force --describe --file /tmp/Brewfile.snapshot && echo "Snapshot at /tmp/Brewfile.snapshot — diff against curated brew/Brewfile.{core,personal,work}"'
alias tmux-work='cd "$HOME/Developer/active/blur-platform" && tmux'
alias weekly-oil-check='brew update && brew upgrade && brew cleanup && bash "$HOME/Developer/workspaces/macstrap/scripts/dev-doctor.sh"'
alias weekly-oil-change='weekly-oil-check'
