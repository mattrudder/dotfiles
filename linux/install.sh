#!/usr/bin/env bash


# Install apt based dependencies
if [ -x "$(command -v apt)" ]; then
    while IFS= read -r line || [ -n "$line" ]
    do
    which $line >/dev/null || yes | sudo apt install $line
    done < "$DOTFILES_DIR/linux/apt-deps"
fi

# Change shell to zsh
chsh -s /usr/bin/zsh