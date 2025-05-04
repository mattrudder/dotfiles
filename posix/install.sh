#!/usr/bin/env bash

NVIM_DATA_DIR="$HOME/.local/share/nvim"
PACKER_HOME="$NVIM_DATA_DIR/site/pack/packer/start/packer.nvim"
if ! [ -d "$PACKER_HOME" ]; then
  git clone --depth 1 https://github.com/wbthomason/packer.nvim "$PACKER_HOME"
fi

if ! [ -d "$HOME/dev" ]; then
  mkdir $HOME/dev
fi

if ! [ -d "$HOME/dev/marmot.nvim" ]; then
  git clone --depth 1 git@github.com:mattrudder/marmot.nvim "$HOME/dev/marmot.nvim"
  pushd "$HOME/dev/marmot.nvim"
  git remote add upstream "git@github.com:rktjmp/lush-template.git"
  popd
fi
