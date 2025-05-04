
# TODO: Add force parameter
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Get-Command 'winget' -ErrorAction SilentlyContinue)) {
    Write-Output "Configuration requires winget: https://docs.microsoft.com/en-us/windows/package-manager/winget/"
    Write-Output "Please install winget before running this"
    Exit
}
else {
    winget import -i $PSScriptRoot/winget-packages.json
}

# Activate mise and install devtools
if (Get-Command 'mise' -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (mise activate pwsh | Out-String) })
    Invoke-Expression "mise install"
}

# Get an array of currently installed extensions
$vs_ext = code --list-extensions
$vs_ext = $vs_ext -split '`r`n'

foreach ($line in Get-Content $PSScriptRoot\vsix) {
    if (-not ($vs_ext -contains $line)) {
        Write-Output "installing vscode extension $line..."
        code --force --install-extension $line > $null
    }
}

# Install dependencies from cargo-deps
foreach ($line in Get-Content $PSScriptRoot\..\cargo-deps) {
    if (-not (Get-Command $line -ErrorAction SilentlyContinue)) {
        Write-Output "installing $line..."
        cargo install $line --force --quiet
    }
    else {
        Write-Output "$line already installed"
    }
}

# Install pwsh dependencies
if (-not (Get-Module -ListAvailable -Name DockerCompletion)) {
    Write-Output "installing latest DockerCompletion module..."
    Install-Module -Name DockerCompletion -Confirm:$False -Force -Scope CurrentUser | Out-Null
}
else {
    Write-Output "module DockerCompletion already installed"
}

# pwsh module generation
New-Item -ItemType Directory -Path $PSScriptRoot\modules -Force | Out-Null

# Stow for dotfile management
cargo install --git https://github.com/mattrudder/rstow --branch 'symlink-windows' --quiet

mkdir $HOME/.config -ErrorAction SilentlyContinue

rstow -s $PSScriptRoot/../fish -t $HOME
rstow -s $PSScriptRoot/../bat -t $HOME
rstow -s $PSScriptRoot/../zsh -t $HOME
rstow -s $PSScriptRoot/../git -t $HOME
rstow -s $PSScriptRoot/../bin -t $HOME
rstow -s $PSScriptRoot/../wezterm -t $HOME
rstow -s $PSScriptRoot/../starship -t $HOME
rstow -s $PSScriptRoot/../nvim -t $Env:LOCALAPPDATA
rstow -s $PSScriptRoot/../alacritty -t $Env:LOCALAPPDATA


# New-Item -ItemType Directory -Path $Env:LOCALAPPDATA\nvim-data\site\autoload -Force | Out-Null
# $uri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
# (New-Object Net.WebClient).DownloadFile(
#     $uri,
#     $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
#         "$Env:LOCALAPPDATA\nvim-data\site\autoload\plug.vim"
#     )
# )
