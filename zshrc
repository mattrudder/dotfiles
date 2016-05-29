export TERM=xterm-256color

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Path to my custom zsh configuration.
ZSH_CUSTOM=$HOME/.dotfiles/zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="mtr"

# Super cool file renaming! http://www.mfasold.net/blog/2008/11/moving-or-renaming-multiple-files/
# Ex: mmv Foo-*.jpg Bar-*.jpg
# Ex: zmv '(*).lis' '$1.txt'
autoload -U zmv
alias mmv='noglob zmv -W'

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias yt="youtube-dl --max-quality mp4 --add-metadata --output \"%(title)s.mp4\""
alias s="screen -U"
alias sr="screen -dr"
alias fsi="fsharpi"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(common-aliases cp emoji gem git git-extras git-flow github gitignore osx brew brew-cask catimg encode64 urltools docker nanoc npm sudo screen)
source $ZSH/oh-my-zsh.sh

PATH=/usr/local/bin:$PATH

# boxen
if [ -f /opt/boxen/env.sh ]; then
  source /opt/boxen/env.sh
fi

# Rust 
if [ -f $HOME/.cargo/env ]; then
  source $HOME/.cargo/env
fi

# Load machine specific changes from a separate file.
if [ -f ~/.local.zshrc ]; then
  source ~/.local.zshrc
fi

export CXXFLAGS=-ferror-limit=5

PATH=$HOME/.dotfiles/bin:$PATH # dotfiles stuff

if [[ "$(uname)" == "Darwin" ]]; then
  if [ -f $HOME/.dotfiles/zshrc.osx ]; then
    source $HOME/.dotfiles/zshrc.osx
  fi
elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
  if [ -f $HOME/.dotfiles/zshrc.linux ]; then
    source $HOME/.dotfiles/zshrc.linux
  fi
elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]]; then
  if [ -f $HOME/.dotfiles/zshrc.windows ]; then
    source $HOME/.dotfiles/zshrc.windows
  fi
fi

export ALTERNATIVE_EDITOR=emacs
export EDITOR=$HOME/.dotfiles/bin/edit
