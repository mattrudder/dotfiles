#!/usr/bin/env bash

if ! [ -d "$HOME/.asdf" ]; then
  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.12.0
fi

. "$HOME/.asdf/asdf.sh"

asdf plugin add neovim https://github.com/richin13/asdf-neovim
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs
asdf plugin add yarn https://github.com/twuni/asdf-yarn
asdf plugin add golang https://github.com/asdf-community/asdf-golang
asdf plugin add zig https://github.com/cheetah/asdf-zig

asdf install