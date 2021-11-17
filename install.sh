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

# Install Rust + rstow
which rustup >/dev/null || curl --proto '=https' --tlsv1.2 -sS https://sh.rustup.rs | sh -s -- --profile default --default-toolchain stable -y
source $HOME/.cargo/env

cargo install --git https://github.com/qboileau/rstow

if ! [ -d "$HOME/.config" ]; then
  mkdir -p "$HOME/.config"
fi

function link {
  local src=$1
  local dest=$2

  ln -sFi "$src" "$dest"
}

# vim configs
sh -c 'curl -fLo "${HOME}/.vim/autoload/plug.vim" --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# .configs
rstow -s $SCRIPT_PATH/fish -t $HOME
rstow -s $SCRIPT_PATH/bat -t $HOME
rstow -s $SCRIPT_PATH/zsh -t $HOME
rstow -s $SCRIPT_PATH/git -t $HOME
rstow -s $SCRIPT_PATH/bin -t $HOME
rstow -s $SCRIPT_PATH/nvim -t $HOME/.config
rstow -s $SCRIPT_PATH/alacritty -t $HOME/.config

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Installing macOS specific dependencies..."
  source $SCRIPT_PATH/macos/install.sh
elif [[ "$OSTYPE" == "linux"* ]]; then
  echo "Installing Linux specific dependencies..."
  source $SCRIPT_PATH/linux/install.sh
else
  echo "No platform specific dependencies for $OSTYPE!"
fi

which volta >/dev/null || curl https://get.volta.sh | bash

# Install cargo based dependencies
while IFS= read -r line || [ -n "$line" ] 
do
  which $line >/dev/null || cargo install --locked --force $line
done < "$DOTFILES_DIR/cargo-deps"

BASE16_DIR="$DOTFILES_DIR/base16"
mkdir -p "$BASE16_DIR"
if [ ! -d "$BASE16_DIR/shell" ]; then
  git clone https://github.com/chriskempson/base16-shell.git "$BASE16_DIR/shell"
fi
