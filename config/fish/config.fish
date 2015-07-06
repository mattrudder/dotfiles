prepend_to_path $HOME/bin

set -g fish_greeting

#
# Directories
#
set -gx DOCS "$HOME/Documents"
set -gx DROPBOX "$HOME/Dropbox"
set -gx NOTES "$HOME/Notes"
set -gx CODE "$HOME/src"

append_to_cdpath "."
append_to_cdpath "$CODE"

set fish_path $HOME/.dotfiles/config/fish

#
# Colors
#
set -gx CLICOLOR 1
set -g fish_color_command     green   --bold
set -g fish_color_cwd         yellow
set -g fish_color_end         green
set -g fish_color_error       red     --bold
set -g fish_color_escape      purple
set -g fish_color_param       green
set -g fish_color_quote       yellow
set -g fish_color_valid_path  blue    --underline

set -l FISH_BOXEN $fish_path/boxen.fish
test -r $FISH_BOXEN; and test -d /opt/boxen; and source $FISH_BOXEN
