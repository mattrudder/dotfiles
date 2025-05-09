prepend_to_path $HOME/bin

source (starship init fish --print-full-init | psub)

set -g fish_greeting

#
# Directories
#
set -gx DOCS "$HOME/Documents"
set -gx DROPBOX "$HOME/Dropbox"
set -gx NOTES "$HOME/Notes"
set -gx CODE "$HOME/dev"
set -gx STARSHIP_CONFIG "$HOME/.dotfiles/starship.toml"


append_to_cdpath "."
append_to_cdpath "$CODE"

set fish_home $HOME/.dotfiles/fish

# Rust
set -gx KERN_NAME (string lower (uname -s))
set -gx CARGO_TARGET_DIR target/$KERN_NAME
prepend_to_path $HOME/.cargo/bin

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

. $fish_home/aliases.fish

starship init fish | source
mise activate fish | source
