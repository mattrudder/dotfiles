#!/usr/bin/env bash


# Install apt based dependencies
if [ -x "$(command -v apt)" ]; then
    echo "installing apt dependencies..."
    apt update -y
    while IFS= read -r line || [ -n "$line" ]
    do
    which $line >/dev/null || yes | sudo apt install -y $line
    done < "$DOTFILES_DIR/linux/apt-deps"

    # TODO: Install mise
    # sudo install -dm 755 /etc/apt/keyrings
    # wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null
    # echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list

    # sudo apt update
    # sudo apt install -y mise
fi

# Install yum based dependencies (AL2)
if [ -x "$(command -v yum)" ]; then
    echo "installing yum dependencies..."
    while IFS= read -r line || [ -n "$line" ]
    do
    rpm -q $line || sudo yum install -y $line
    done < "$DOTFILES_DIR/linux/yum-deps"

    # TODO: Install mise
    # yum-config-manager --add-repo https://mise.jdx.dev/rpm/mise.repo
    # sudo yum install -y mise
fi

# Change shell to zsh
echo "changing shell to zsh..."
chsh -s /usr/bin/zsh 2>&1 >/dev/null
