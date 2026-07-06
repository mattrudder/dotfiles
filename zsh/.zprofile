# OS-specific config
if [[ "$OSTYPE" == "darwin"* ]]; then
  source $DOTFILES_DIR/macos/.zprofile
elif [[ "$OSTYPE" == "linux"* ]]; then
  source $DOTFILES_DIR/linux/.zprofile
fi
