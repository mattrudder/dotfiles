
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
    & mise install
    & mise activate pwsh | Out-String | Invoke-Expression
} else {
    Write-Output "Installation requires mise in path"
    Write-Output "Please restart your terminal and run the installer again"
    Exit
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
# TODO: consider upgrading this to cargo-binstall
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
rstow -s $PSScriptRoot/../tools -t $HOME
rstow -s $PSScriptRoot/../nvim -t $Env:LOCALAPPDATA
rstow -s $PSScriptRoot/../alacritty -t $Env:LOCALAPPDATA
rstow -s $PSScriptRoot/../mise -t $HOME
rstow -s $PSScriptRoot/../emacs -t $HOME
rstow -s $PSScriptRoot/../omnivoice -t $HOME
rstow -s $PSScriptRoot/../vox -t $HOME

# The private half: things that must not be in a public repo. Same layout, same
# tool. Warns rather than skipping quietly -- without it omnivoice-server has no
# voices config and refuses to start.
$private = "$PSScriptRoot/../../dotfiles-private"
if (Test-Path $private) {
    foreach ($pkg in Get-ChildItem -Path $private -Directory) {
        rstow -s $pkg.FullName -t $HOME
    }
}
else {
    Write-Warning ("dotfiles-private is not cloned at $private, so ~/.config/omnivoice " +
        "will be missing and omnivoice-server will refuse to start. " +
        "git clone git@github.com:mattrudder/dotfiles-private.git $private")
}

# --- User PATH entries -------------------------------------------------------
#
# Order matters, not just presence: ~/.cargo/bin must come AFTER the mise shims,
# or a stale `cargo install` binary silently wins over mise's pinned version.
function Set-UserPathEntry {
    param(
        [Parameter(Mandatory)][string]$Entry,
        # Regex for an entry this one must never precede. Omit when order is free.
        [string]$MustFollow
    )
    $current = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @(($current -split ';') | Where-Object { $_ })
    $entryAt = [Array]::FindIndex($parts, [Predicate[string]] { $args[0].TrimEnd('\') -ieq $Entry.TrimEnd('\') })
    $afterAt = if ($MustFollow) { [Array]::FindIndex($parts, [Predicate[string]] { $args[0] -match $MustFollow }) } else { -1 }

    # Present and correctly ordered: don't rewrite the PATH for nothing.
    if ($entryAt -ge 0 -and ($afterAt -lt 0 -or $entryAt -gt $afterAt)) { return }

    if ($entryAt -ge 0) {
        Write-Host "install: moving $Entry below the mise shims on PATH"
        $parts = @($parts[0..($parts.Count - 1)] | Where-Object { $_ -ne $parts[$entryAt] })
    }
    [Environment]::SetEnvironmentVariable("Path", (($parts + $Entry) -join ';'), "User")
}

Set-UserPathEntry -Entry "$env:USERPROFILE\.local\bin"
# The regex matches mise's shim dir on Windows and elsewhere.
Set-UserPathEntry -Entry "$env:USERPROFILE\.cargo\bin" -MustFollow 'mise[\\/]shims'

# New-Item -ItemType Directory -Path $Env:LOCALAPPDATA\nvim-data\site\autoload -Force | Out-Null
# $uri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
# (New-Object Net.WebClient).DownloadFile(
#     $uri,
#     $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
#         "$Env:LOCALAPPDATA\nvim-data\site\autoload\plug.vim"
#     )
# )
