[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$stateDir  = Join-Path $PSScriptRoot 'state'
$statePath = Join-Path $stateDir 'display-state.xml'
$logPath   = Join-Path $stateDir 'apollo.log'

function Write-ApolloLog {
    param([string]$Level, [string]$Message)
    $line = "[{0}] {1}: {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
    Add-Content -LiteralPath $logPath -Value $line -Encoding utf8
}

try {
    if (-not (Test-Path $statePath)) {
        Write-ApolloLog 'disconnect' "No saved display state at $statePath; nothing to restore."
        exit 0
    }

    if (-not (Get-Module -ListAvailable -Name DisplayConfig)) {
        $vendored = Join-Path $PSScriptRoot '..\pwsh\modules\DisplayConfig\5.2.1\DisplayConfig.psd1'
        Import-Module $vendored -ErrorAction Stop
    } else {
        Import-Module DisplayConfig -ErrorAction Stop
    }

    Import-Clixml -LiteralPath $statePath | Use-DisplayConfig
    Write-ApolloLog 'disconnect' "Restored display config from $statePath"

    Remove-Item -LiteralPath $statePath -Force
    exit 0
}
catch {
    Write-ApolloLog 'error' ("disconnect failed: " + $_.Exception.Message)
    throw
}
