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

# Get script directory, relative to the dotfiles repo
SCRIPT_PATH=${(%):-%x}
SCRIPT_DIR=$(readlink $(dirname $SCRIPT_PATH))
export DOTFILES_DIR=$(dirname $SCRIPT_DIR)
export BASE16_DIR="$DOTFILES_DIR/base16"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Go
export GOPATH="$HOME/dev/go"
export PATH="$GOPATH/bin:$PATH"

eval "$(starship init zsh)"

# JS
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

if [[ "$OSTYPE" == "darwin"* ]]; then
  source $DOTFILES_DIR/macos/.zshrc 
elif [[ "$OSTYPE" == "linux"* ]]; then
  source $DOTFILES_DIR/linux/.zshrc 
fi

# Base16 Shell
export CLICOLOR=1
BASE16_SHELL="$BASE16_DIR/shell"
[ -n "$PS1" ] && \
    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        eval "$("$BASE16_SHELL/profile_helper.sh")"

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
