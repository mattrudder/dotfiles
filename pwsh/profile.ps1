Invoke-Expression (&starship init powershell)

Import-Module DockerCompletion
Import-Module $PSScriptRoot\modules\rustup.psm1

if (Test-Path $Env:VCPKG_ROOT\scripts\posh-vcpkg) {
    Import-Module $Env:VCPKG_ROOT\scripts\posh-vcpkg
}

if (Test-Path $PSScriptRoot\modules\visualstudio.psm1) {
    Import-Module $PSScriptRoot\modules\visualstudio.psm1
}

<#
.SYNOPSIS
    Invokes a command and imports its environment variables.

.DESCRIPTION
    It invokes any cmd shell command (normally a configuration batch file) and
    imports its environment variables to the calling process. Command output is
    discarded completely. It fails if the command exit code is not 0. To ignore
    the exit code use the 'call' command.

.EXAMPLE
    # Invokes Config.bat in the current directory or the system path
    Invoke-Environment Config.bat

.EXAMPLE
    # Visual Studio environment: works even if exit code is not 0
    Invoke-Environment 'call "%VS100COMNTOOLS%\vsvars32.bat"'

.EXAMPLE
    # This command fails if vsvars32.bat exit code is not 0
    Invoke-Environment '"%VS100COMNTOOLS%\vsvars32.bat"'
#>
function Invoke-Environment {
    param
    (
        # Any cmd shell command, normally a configuration batch file.
        [Parameter(Mandatory=$true)]
        [string] $Command
    )

    $Command = "`"" + $Command + "`""
    cmd /c "$Command > nul 2>&1 && set" | . { process {
        if ($_ -match '^([^=]+)=(.*)') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }}

}

# Visual Studio Environment
# Invoke-Environment for vsvars64.bat, using vswhere to lookup install path.
$vswhere = Join-Path ${Env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $vsPath = & $vswhere -latest -property installationPath
    if ($vsPath) {
        $vsvars = Join-Path $vsPath "Common7\Tools\VsDevCmd.bat"
        if (Test-Path $vsvars) {
            $cmd = "`"" + $vsvars + "`""
            cmd /c "$cmd -arch=x64 > nul 2>&1 && set" | . { process {
                if ($_ -match '^([^=]+)=(.*)') {
                    [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
                }
            }}
        }
    }
}

$emsdk = "D:\emsdk\emsdk_env.bat"
if (Test-Path $emsdk) {
    Invoke-Environment -Command $emsdk
}

if (Get-Command 'mise' -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (mise activate pwsh | Out-String) })
    # $env:PATH += ";$env:LOCALAPPDATA\mise\shims" 
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

Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })

Remove-Alias "ls"

function ls { lsd.exe --icon never $args }
function ll { lsd.exe --icon never -l $args }
function la { lsd.exe --icon never -a $args }
function lla { lsd.exe --icon never -la $args }
function lt { lsd.exe --icon never --tree $args }
