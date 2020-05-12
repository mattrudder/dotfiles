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

if ! [ -d "$HOME/.config" ]; then
  mkdir -p "$HOME/.config"
fi

function link {
  local src=$1
  local dest=$2

  ln -sFi "$src" "$dest"
}

# vim configs
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# .configs
ln -sFi $SCRIPT_PATH/fish/ ~/.config/
ln -sFi $SCRIPT_PATH/nvim/ ~/.config/

# Git configs
ln -sFi $SCRIPT_PATH/gitconfig ~/.gitconfig
ln -sFi $SCRIPT_PATH/githelpers ~/.githelpers
ln -sFi $SCRIPT_PATH/gitignore ~/.gitignore

which rustup >/dev/null || curl --proto '=https' --tlsv1.2 -sS https://sh.rustup.rs | sh
which starship >/dev/null || cargo install starship --force --quiet
which volta >/dev/null || curl https://get.volta.sh | bash
