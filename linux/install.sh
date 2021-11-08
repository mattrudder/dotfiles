#!/usr/bin/env bash


# Install apt based dependencies
if [ -x "$(command -v apt)" ]; then
    echo "installing apt dependencies..."
    while IFS= read -r line || [ -n "$line" ]
    do
    which $line >/dev/null || yes | sudo apt install $line
    done < "$DOTFILES_DIR/linux/apt-deps"
fi

# Change shell to zsh
echo "changing shell to zsh..."
chsh -s /usr/bin/zsh 2>&1 >/dev/null