function make-link ($target, $link) {
  New-Item -Path $link -ItemType SymbolicLink -Value $target -Force | Out-Null
}

make-link $PWD\pwsh $HOME\Documents\PowerShell

. $PWD\pwsh\install.ps1
