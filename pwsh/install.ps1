
# TODO: Add force parameter
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Install Scoop
if (-not (Get-Command scoop)) {
    Write-Output "installing scoop..."
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh') | Out-Null
} else {
    Write-Output "scoop already installed!"
}

$scoopapps = scoop export | ForEach-Object {
  $_.Split()[0]
}

$scoopdeps = Get-Content $PSScriptRoot\scoopdeps

if ($scoopdeps) {
    foreach ($line in Get-Content $PSScriptRoot\scoopdeps) {
        if (-not ($scoopapps -contains $line)) {
            Write-Output "installing scoop package $line..."
            scoop install $line > $null
        }
    }
}

if (-not (Get-Command code)) {
    Write-Output "installing vscode..."
    scoop install vscode > $null
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

# Install Starship
if (-not (Get-Command starship)) {
    Write-Output "installing starship.rs..."
    cargo install starship --force --quiet
} else {
    Write-Output "starship.rs already installed"
}

# Install Shell Dependencies
if (-not (Get-Module -ListAvailable -Name DockerCompletion)) {
    Write-Output "installing latest DockerCompletion module..."
    Install-Module -Name DockerCompletion -Confirm:$False -Force -Scope CurrentUser | Out-Null
} else {
    Write-Output "module DockerCompletion already installed"
}

# pwsh module generation
New-Item -ItemType Directory -Path $PSScriptRoot\modules -Force | Out-Null

# Update rustup completions
if (Get-Command rustup) {
    Write-Output "updating rustup completions..."
    rustup completions powershell > $PSScriptRoot\modules\rustup.psm1
} else {
    Write-Output "rustup not found! please install rustup first and re-run this command."
}

# Update volta completions
if (Get-Command volta) {
    Write-Output "updating volta completions..."
    volta completions powershell > $PSScriptRoot\modules\volta.psm1
} else {
    Write-Output "volta not found! please install volta first and re-run this command"
}
