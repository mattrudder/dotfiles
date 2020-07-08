# iTerm2 Integration
test -e "$DOTFILES_DIR/macos/.iterm2_shell_integration.zsh" && source "$DOTFILES_DIR/macos/.iterm2_shell_integration.zsh"

# Aliases
alias dircolors=gdircolors
alias ls='gls -G --color=auto'
alias la='gls -Gla --color=auto'
alias chromedbg='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222'
alias firefoxdbg='/Applications/Firefox.app/Contents/MacOS/firefox -start-debugger-server'

export PATH=$HOME/Library/Python/3.7/bin:$PATH