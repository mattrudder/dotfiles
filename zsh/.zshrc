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

export PATH="$HOME/.cargo/bin:$PATH"

eval "$(starship init zsh)"

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

if [[ "$OSTYPE" == "darwin"* ]]; then
  source $DOTFILES_DIR/macos/.zshrc 
fi
