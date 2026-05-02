[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$VirtualDisplayName,

    [int]$TimeoutSeconds = 10,

    [int]$PollIntervalMs = 500
)

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
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }

    if (-not (Get-Module -ListAvailable -Name DisplayConfig)) {
        $vendored = Join-Path $PSScriptRoot '..\pwsh\modules\DisplayConfig\5.2.1\DisplayConfig.psd1'
        Import-Module $vendored -ErrorAction Stop
    } else {
        Import-Module DisplayConfig -ErrorAction Stop
    }

    Get-DisplayConfig | Export-Clixml -LiteralPath $statePath -Depth 10
    Write-ApolloLog 'connect' "Saved current display config to $statePath"

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $virtual = $null
    while ($null -eq $virtual) {
        $virtual = Get-DisplayInfo |
            Where-Object { $_.Active -and $_.DisplayName -eq $VirtualDisplayName } |
            Select-Object -First 1
        if ($virtual) { break }
        if ((Get-Date) -ge $deadline) {
            throw "Virtual display '$VirtualDisplayName' did not appear within $TimeoutSeconds seconds."
        }
        Start-Sleep -Milliseconds $PollIntervalMs
    }

    $virtualId = $virtual.DisplayId
    Write-ApolloLog 'connect' "Resolved virtual display '$VirtualDisplayName' to DisplayId $virtualId"

    $cfg = Get-DisplayConfig | Set-DisplayPrimary -DisplayId $virtualId
    $others = Get-DisplayInfo | Where-Object { $_.Active -and $_.DisplayId -ne $virtualId }
    foreach ($d in $others) {
        $cfg = $cfg | Disable-Display -DisplayId $d.DisplayId
    }
    $cfg | Use-DisplayConfig

    Write-ApolloLog 'connect' ("Disabled {0} other display(s); '{1}' is primary." -f $others.Count, $VirtualDisplayName)
    exit 0
}
catch {
    Write-ApolloLog 'error' ("connect failed: " + $_.Exception.Message)
    throw
}
