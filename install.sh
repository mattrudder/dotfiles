#!/bin/sh

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

function link {
  local src=$1
  local dest=$2

  #if [ -e "$dest" ] || [ -h "$dest" ]; then

  #  read -p "File $dest already exists. Overwrite? [Y/n] " -n 1 -r
  #  echo

  #  if [[ $REPLY =~ ^[Nn]$ ]]; then
  #    return
  #  fi

  #  rm -f "$dest"
  #fi

  #echo "ln -s '$src' '$dest'"
  ln -sFi "$src" "$dest"
}

# vim configs
ln -sFi $SCRIPT_PATH/vimrc ~/.vimrc
ln -sFi $SCRIPT_PATH/vim/ ~/.vim

# zsh configs
ln -sFi $SCRIPT_PATH/zshrc ~/.zshrc

# Git configs
ln -sFi $SCRIPT_PATH/gitconfig ~/.gitconfig
ln -sFi $SCRIPT_PATH/githelpers ~/.githelpers

