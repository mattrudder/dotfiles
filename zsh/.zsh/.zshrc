setopt NO_CASE_GLOB
setopt AUTO_CD
setopt CORRECT

setopt EXTENDED_HISTORY

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
SAVEHIST=5000
HISTSIZE=2000

# share history across multiple zsh sessions
setopt SHARE_HISTORY
# append to history
setopt APPEND_HISTORY
# adds commands as they are typed, not at shell exit
setopt INC_APPEND_HISTORY
# expire duplicates first
setopt HIST_EXPIRE_DUPS_FIRST 
# do not store duplications
setopt HIST_IGNORE_DUPS
#ignore duplicates when searching
setopt HIST_FIND_NO_DUPS
# removes blank lines from history
setopt HIST_REDUCE_BLANKS
# do not save history entries when starting the command with a space
setopt HIST_IGNORE_SPACE

# Get script directory, relative to the dotfiles repo
SCRIPT_PATH=${(%):-%x}
SCRIPT_DIR=$(readlink $(dirname $SCRIPT_PATH))
ZSHRC_DIR=$(dirname $SCRIPT_DIR)
export DOTFILES_DIR=$(dirname $ZSHRC_DIR)
export BASE16_DIR="$DOTFILES_DIR/base16"

# Dotfiles Scripts
export PATH="$HOME/bin:$PATH"

# Mise
eval "$(mise activate zsh)"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Go
export GOPATH="$HOME/dev/go"
export PATH="$GOPATH/bin:$PATH"

eval "$(starship init zsh)"

# JS
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"

if [[ "$OSTYPE" == "darwin"* ]]; then
  source $DOTFILES_DIR/macos/.zshrc
elif [[ "$OSTYPE" == "linux"* ]]; then
  source $DOTFILES_DIR/linux/.zshrc
fi

# Base16 Shell
export CLICOLOR=1
# BASE16_SHELL="$BASE16_DIR/shell"
# [ -n "$PS1" ] && \
#     [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
#         eval "$("$BASE16_SHELL/profile_helper.sh")"

# Load Git completion
zstyle ':completion:*:*:git:*' script $ZDOTDIR/functions/git-completion.bash
fpath=($ZDOTDIR/functions $fpath)

autoload -Uz compinit && compinit

eval `dircolors $ZDOTDIR/.dircolors`

# Aliases
alias cat='bat'
alias ls='lsd --icon never'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# Bindings (include spaces to avoid flooding history)
bindkey -s ^f " tmux-sessionizer; fc -R\n"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
