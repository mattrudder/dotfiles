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

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Installing macOS specific dependencies..."
  source $SCRIPT_PATH/macos/install.sh
elif [[ "$OSTYPE" == "linux"* ]]; then
  echo "Installing Linux specific dependencies..."
  source $SCRIPT_PATH/linux/install.sh
else
  echo "No platform specific dependencies for $OSTYPE!"
fi

source $SCRIPT_PATH/posix/install.sh
if command -v mise &>/dev/null; then
  mise trust -y
  eval "$(mise activate bash)"
  mise install

  # Ensure we can call mise tools and cargo installed tools within this same execution.
  export PATH="$HOME/.local/share/mise/shims:$HOME/.cargo/bin:$PATH"
elif [ -f "$HOME/.cargo/env" ]; then
  source $HOME/.cargo/env
fi

# Install cargo based dependencies
while IFS= read -r line || [ -n "$line" ]
do
  which $line >/dev/null || cargo install --locked --force $line
done < "$DOTFILES_DIR/cargo-deps"

# Install rstow for config management
mise exec -- cargo install --git https://github.com/qboileau/rstow --quiet

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


function stow {
  local src=$1
  local dest=$2

  echo "❯❯❯ Stowing $src to $dest"
  rstow -f -s "$src" -t "$dest"
}

# .configs
stow $SCRIPT_PATH/fish $HOME
stow $SCRIPT_PATH/bat $HOME
stow $SCRIPT_PATH/zsh $HOME
stow $SCRIPT_PATH/git $HOME
stow $SCRIPT_PATH/bin $HOME
stow $SCRIPT_PATH/tmux $HOME
stow $SCRIPT_PATH/wezterm $HOME
stow $SCRIPT_PATH/starship $HOME
stow $SCRIPT_PATH/mise $HOME
stow $SCRIPT_PATH/emacs $HOME

stow $SCRIPT_PATH/nvim $HOME/.config
stow $SCRIPT_PATH/alacritty $HOME/.config
stow $SCRIPT_PATH/kitty $HOME/.config
# stow $SCRIPT_PATH/starship $HOME/.config

# Setup dotfiles-local overlay symlink
if [ ! -e "$HOME/.dotfiles-local" ]; then
  echo ""
  read -p "Set up a private dotfiles overlay? (y/n) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Path to private dotfiles repo: " overlay_path
    if [ -d "$overlay_path" ]; then
      ln -s "$overlay_path" "$HOME/.dotfiles-local"
      echo "✓ Linked ~/.dotfiles-local -> $overlay_path"
    else
      echo "Directory not found: $overlay_path"
    fi
  fi
fi


BASE16_DIR="$DOTFILES_DIR/base16"
mkdir -p "$BASE16_DIR"
if [ ! -d "$BASE16_DIR/shell" ]; then
  git clone https://github.com/chriskempson/base16-shell.git "$BASE16_DIR/shell"
fi
