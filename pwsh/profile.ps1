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

function ssh-copy-id([string]$userAtMachine) {
    if ($userAtMachine -eq "") {
        Write-Error "USAGE: ssh-copy-id user@server.hostname"
        return
    }

    $publicKey = "$ENV:USERPROFILE" + "/.ssh/id_rsa.pub"
    if (!(Test-Path "$publicKey")) {
        Write-Error "ERROR: failed to open ID file '$publicKey': No such file" 
        return           
    }
    
    & Get-Content "$publicKey" | ssh $userAtMachine "umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys || exit 1"
}

New-Alias which Get-Command

Remove-Alias "ls"

function ls { lsd.exe --icon never $args }
function ll { lsd.exe --icon never -l $args }
function la { lsd.exe --icon never -a $args }
function lla { lsd.exe --icon never -la $args }
function lt { lsd.exe --icon never --tree $args }
