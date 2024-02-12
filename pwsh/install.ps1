
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

if (-not (Get-Command 'choco' -ErrorAction SilentlyContinue)) {
    $InstallDir = 'C:\ProgramData\chocoportable'
    $env:ChocolateyInstall = "$InstallDir"
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

choco install mingw neovim -y

if (-not (Get-Command 'code' -ErrorAction SilentlyContinue)) {
    Write-Output "installing vscode..."
    winget install vscode-system-x64 > $null
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

if (-not (Get-Command 'rustup' -ErrorAction SilentlyContinue)) {
    $rustup_init = (New-TemporaryFile).Name
    Start-BitsTransfer -Source "https://win.rustup.rs/x86_64" -Destination "$rustup_init"
    Move-Item -Path $rustup_init -Destination "rustup-init.exe" -Force
    & ".\rustup-init.exe" -q -y
    Write-Output "Restart your terminal and run .\install.ps1 again"
    Exit
}

# Update rustup completions
if (Get-Command 'rustup' -ErrorAction SilentlyContinue) {
    Write-Output "updating rustup completions..."
    rustup completions powershell > $PSScriptRoot\modules\rustup.psm1
}
else {
    (New-Object System.Net.WebClient).DownloadFile("https://win.rustup.rs/x86_64", "rustup-init.exe")
    Write-Output "rustup not found! please install rustup first and re-run this command."
}

# Install Starship
if (-not (Get-Command 'starship' -ErrorAction SilentlyContinue)) {
    Write-Output "installing starship.rs..."
    cargo install starship --force --quiet
}
else {
    Write-Output "starship.rs already installed"
}

# Install Shell Dependencies
if (-not (Get-Module -ListAvailable -Name DockerCompletion)) {
    Write-Output "installing latest DockerCompletion module..."
    Install-Module -Name DockerCompletion -Confirm:$False -Force -Scope CurrentUser | Out-Null
}
else {
    Write-Output "module DockerCompletion already installed"
}

# pwsh module generation
New-Item -ItemType Directory -Path $PSScriptRoot\modules -Force | Out-Null

# Update volta completions
if (Get-Command 'volta' -ErrorAction SilentlyContinue) {
    Write-Output "updating volta completions..."
    volta completions powershell > $PSScriptRoot\modules\volta.psm1
}
else {
    Write-Output "volta not found! please install volta first and re-run this command"
}

# Stow for dotfile management
cargo install --git https://github.com/mattrudder/rstow --branch 'symlink-windows'

rstow -s $PSScriptRoot/../fish -t $HOME
rstow -s $PSScriptRoot/../bat -t $HOME
rstow -s $PSScriptRoot/../zsh -t $HOME
rstow -s $PSScriptRoot/../git -t $HOME
rstow -s $PSScriptRoot/../bin -t $HOME
rstow -s $PSScriptRoot/../wezterm -t $HOME
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
