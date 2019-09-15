function make-link ($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target -Force
}

make-link $PWD\vimrc $HOME\.vimrc
make-link $PWD\vim $HOME\.vim

make-link $PWD\zshrc $HOME\.zshrc

make-link $PWD\gitconfig $HOME\.gitconfig
make-link $PWD\githelpers $HOME\.githelpers

make-link $PWD\oh-my-zsh $HOME\.oh-my-zsh
