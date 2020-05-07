[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Env:TERM="xterm-256colors"

Invoke-Expression (&starship init powershell)

Import-Module DockerCompletion
Import-Module $PSScriptRoot\modules\rustup.psm1
Import-Module $PSScriptRoot\modules\volta.psm1

if (Test-Path $Env:VCPKG_ROOT\scripts\posh-vcpkg) {
    Import-Module $Env:VCPKG_ROOT\scripts\posh-vcpkg
}

if (Test-Path $PSScriptRoot\modules\visualstudio.psm1) {
    Import-Module $PSScriptRoot\modules\visualstudio.psm1
}

function New-Link ($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target -Force | Out-Null
}

New-Alias which Get-Command
