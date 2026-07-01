#!/usr/bin/env bash
#
# macOS system defaults, opinionated but sensible developer settings.
# Run deliberately (NOT part of bootstrap):  bash scripts/macos-defaults.sh
#
# Every setting here is a reversible preference toggle (no deletions). You can
# undo any of it in System Settings or by flipping the value. Comment out
# anything you disagree with, it's meant to be read and tuned.
#
set -euo pipefail

echo "Applying macOS developer defaults… (close System Settings first)"
# Ask for sudo up front only if needed (most settings are per-user and don't).
# osascript -e 'tell app "System Settings" to quit' 2>/dev/null || true

############################################################
# Keyboard, fast key repeat (great for editing/vim motions)
############################################################
defaults write NSGlobalDomain KeyRepeat -int 2          # fast repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15  # short delay
# Enable key-repeat instead of the accent popup when holding a key:
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Devs usually want these OFF (they mangle code/commands):
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

############################################################
# Finder
############################################################
defaults write NSGlobalDomain AppleShowAllExtensions -bool true   # show file extensions
defaults write com.apple.finder ShowPathbar -bool true           # bottom path bar
defaults write com.apple.finder ShowStatusBar -bool true         # status bar
defaults write com.apple.finder _FXSortFoldersFirst -bool true   # folders first
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"  # list view
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # search current folder
# Don't litter network/USB volumes with .DS_Store files:
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# Show the ~/Library folder:
chflags nohidden "$HOME/Library" 2>/dev/null || true

############################################################
# Screenshots, keep the desktop clean
############################################################
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

############################################################
# Save / print panels, expand by default (less clicking)
############################################################
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

############################################################
# Trackpad, tap to click
############################################################
defaults write com.apple.driver.AppleBitmapTouchpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

############################################################
# Dock, preference, tweak freely
############################################################
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false   # don't reorder Spaces by use

############################################################
# Apply, restart affected apps
############################################################
for app in Finder Dock SystemUIServer; do killall "$app" 2>/dev/null || true; done

echo "Done. Some changes need a logout/restart to fully take effect."
