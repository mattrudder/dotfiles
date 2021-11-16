function make-link ($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target -Force | Out-Null
}


make-link $PWD\git\.gitconfig $HOME\.gitconfig
make-link $PWD\git\.githelpers $HOME\.githelpers
make-link $PWD\git\.gitignore $HOME\.gitignore

make-link $PWD\pwsh $HOME\Documents\PowerShell

. $PWD\pwsh\install.ps1
