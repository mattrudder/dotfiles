[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Invoke-Expression (&starship init powershell)

Import-Module DockerCompletion
Import-Module $PSScriptRoot\modules\rustup.psm1
Import-Module $PSScriptRoot\modules\volta.psm1
if (Test-Path $PSScriptRoot\modules\visualstudio.psm1) {
    Import-Module $PSScriptRoot\modules\visualstudio.psm1
}


New-Alias which Get-Command
