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

export PATH="$HOME/.cargo/bin:$PATH"

eval "$(starship init zsh)"

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

if [[ "$OSTYPE" == "darwin"* ]]; then
  source $DOTFILES_DIR/macos/.zshrc 
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
alias ls='ls -G --color=auto'
alias la='ls -la'
alias cat='bat'