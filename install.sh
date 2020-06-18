#!/bin/bash

# Get directory of script.
pushd . > /dev/null
SCRIPT_PATH="${BASH_SOURCE[0]}";
  while([ -h "${SCRIPT_PATH}" ]) do
    cd "`dirname "${SCRIPT_PATH}"`"
    SCRIPT_PATH="$(readlink "`basename "${SCRIPT_PATH}"`")";
  done
cd "`dirname "${SCRIPT_PATH}"`" > /dev/null
SCRIPT_PATH="`pwd`";
popd > /dev/null

export DOTFILES_DIR=$SCRIPT_PATH

if ! [ -d "$HOME/.config" ]; then
  mkdir -p "$HOME/.config"
fi

function link {
  local src=$1
  local dest=$2

  ln -sFhi "$src" "$dest"
}

# vim configs
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# .configs
ln -sFhi $SCRIPT_PATH/fish/ ~/.config/
ln -sFhi $SCRIPT_PATH/nvim/ ~/.config/

# zsh configs
ln -sFhi $SCRIPT_PATH/zsh/.zshenv ~/.zshenv
ln -sFhi $SCRIPT_PATH/zsh ~/.zsh


# Git configs
ln -sFhi $SCRIPT_PATH/gitconfig ~/.gitconfig
ln -sFhi $SCRIPT_PATH/githelpers ~/.githelpers
ln -sFhi $SCRIPT_PATH/gitignore ~/.gitignore

which rustup >/dev/null || curl --proto '=https' --tlsv1.2 -sS https://sh.rustup.rs | sh
which starship >/dev/null || cargo install starship --force
which volta >/dev/null || curl https://get.volta.sh | bash


BASE16_DIR="$DOTFILES_DIR/base16"
mkdir -p $BASE16_DIR
if [ ! -d "$BASE16_DIR/shell" ]; then
  git clone https://github.com/chriskempson/base16-shell.git "$BASE16_DIR/shell"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Installing macOS specific dependencies..."
  source $SCRIPT_PATH/macos/install.sh
fi
