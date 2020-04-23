set-executionpolicy remotesigned -scope currentuser

function make-link ($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target -Force | Out-Null
}

make-link $PWD\vimrc $HOME\.vimrc
make-link $PWD\vimrc $HOME\.nvimrc
make-link $PWD\vim $HOME\.vim

make-link $PWD\zshrc $HOME\.zshrc

make-link $PWD\gitconfig $HOME\.gitconfig
make-link $PWD\githelpers $HOME\.githelpers
make-link $PWD\gitignore $HOME\.gitignore

make-link $PWD\oh-my-zsh $HOME\.oh-my-zsh
make-link $PWD\pwsh $HOME\Documents\PowerShell

. $PWD\pwsh\install.ps1
