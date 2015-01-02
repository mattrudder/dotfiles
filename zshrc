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

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias yt="youtube-dl --max-quality mp4 --add-metadata --output \"%(title)s.mp4\""

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
plugins=(common-aliases git git-extras git-flow osx brew catimg encode64 urltools docker nanoc npm sudo)

source $ZSH/oh-my-zsh.sh

PATH=/usr/local/bin:$PATH

# Load machine specific changes from a separate file.
if [ -f ~/.local.zshrc ]; then
  source ~/.local.zshrc
fi

# aspnet-k
if [ -f /usr/local/bin/kvm.sh ]; then
  source /usr/local/bin/kvm.sh
fi

# boxen
if [ -f /opt/boxen/env.sh ]; then
  source /opt/boxen/env.sh
fi

PATH=$PATH:$HOME/.dotfiles/bin # dotfiles stuff
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
PATH=$PATH:/usr/local/opt/go/libexec/bin

export PATH

#export GOROOT=/usr/local/opt/go/libexec
#export GOPATH=$HOME/Code/Go
#export PATH=$PATH:$GOPATH/bin
#export PATH=$PATH:$HOME/google-cloud-sdk/bin

export LDC_PATH=/usr/local/ldc2
export PATH=$PATH:$LDC_PATH/bin

export XCODE_DIR=`xcode-select --print-path`
alias symbolicate="$XCODE_DIR/Platforms/iPhoneOS.platform/Developer/Library/PrivateFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash -v"

#eval "$(direnv hook $0)"

launchctl setenv PATH $PATH
