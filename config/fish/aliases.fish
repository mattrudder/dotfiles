alias gco="git checkout"
alias gcd="git checkout develop"

alias yt="youtube-dl --max-quality mp4 --add-metadata --output \"%(title)s.mp4\""
alias s="tmux"
alias sr="tmux attach"

alias fsi="fsharpi"

# platform specific aliases
switch (uname)
  case Darwin
    alias xam="open -n -a /Applications/Xamarin\ Studio.app"
end
