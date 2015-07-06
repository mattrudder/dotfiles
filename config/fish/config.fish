# Path to your oh-my-fish.
set fish_path $HOME/.dotfiles/oh-my-fish

# Path to your custom folder (default path is ~/.oh-my-fish/custom)
set fish_custom $HOME/.dotfiles/config/fish/custom

# Load oh-my-fish configuration.
. $fish_path/oh-my-fish.fish

# Custom plugins and themes may be added to ~/.oh-my-fish/custom
# Plugins and themes can be found at https://github.com/oh-my-fish/
#Theme 'l'
#Theme 'integral'
Theme 'clearance'
Plugin 'theme'
Plugin 'balias'
Plugin 'ta'
Plugin 'tab'
Plugin 'ssh'
Plugin 'pbcopy'
Plugin 'osx'
Plugin 'git-flow'
Plugin 'gi'
Plugin 'extract'


balias gco 'git checkout'
balias gcd 'git checkout develop'
