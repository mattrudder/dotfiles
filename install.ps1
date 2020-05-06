set-executionpolicy remotesigned -scope currentuser

function make-link ($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target -Force | Out-Null
}

make-link $PWD\gitconfig $HOME\.gitconfig
make-link $PWD\githelpers $HOME\.githelpers
make-link $PWD\gitignore $HOME\.gitignore

make-link $PWD\config\nvim $LOCALAPPDATA\nvim

make-link $PWD\pwsh $HOME\Documents\PowerShell

. $PWD\pwsh\install.ps1
