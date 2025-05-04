# Global Environment for all zsh instances

export ZDOTDIR=$HOME/.zsh

if [ -f $HOME/.zshlocal ]; then
  source $HOME/.zshlocal
fi

source "$HOME/.cargo/env"


. "$HOME/.cargo/env"
