set-executionpolicy remotesigned -scope currentuser

function make-link ($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target -Force | Out-Null
}

make-link $PWD\gitconfig $HOME\.gitconfig
make-link $PWD\githelpers $HOME\.githelpers
make-link $PWD\gitignore $HOME\.gitignore

make-link $PWD\nvim $Env:LOCALAPPDATA\nvim

New-Item -ItemType Directory -Path $Env:LOCALAPPDATA\nvim-data\site\autoload -Force | Out-Null
$uri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
(New-Object Net.WebClient).DownloadFile(
  $uri,
  $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
    "~\AppData\Local\nvim-data\site\autoload\plug.vim"
  )
)

make-link $PWD\pwsh $HOME\Documents\PowerShell

. $PWD\pwsh\install.ps1
