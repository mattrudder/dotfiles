#!/bin/bash

# Homebrew
which brew > /dev/null 2>&1
if [ $? -eq 1 ]; then
    xcode-select --install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
    brew update
fi

brew tap homebrew/cask-fonts

# Hammerspoon
brew install --cask Hammerspoon
rm -rf $HOME/.hammerspoon
ln -sfn $DOTFILES_DIR/macos/hammerspoon $HOME/.hammerspoon

# System Configs

# Quick key repeat (2 is the lowest you can set in the UI)
defaults write NSGlobalDomain KeyRepeat -int 1

# Dark Mode all the things
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark

# Hide the dock by default
defaults write com.apple.dock autohide -int 1

# Move dock to the left side of the display to free up vertical space
defaults write com.apple.dock orientation -string left

# Get rid of shortcuts on the dock.
defaults read com.apple.dock persistent-apps | grep file-label > /dev/null 2>&1
while [ $? -eq 0 ]; do
    /usr/libexec/PlistBuddy -c "Delete persistent-apps:0" ~/Library/Preferences/com.apple.dock.plist
done
