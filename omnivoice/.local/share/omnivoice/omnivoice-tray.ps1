<#
.SYNOPSIS
    System tray control for omnivoice-server.

.DESCRIPTION
    A coloured dot in the notification area: green when the server is ready,
    amber while it loads, red when it is down. Right-click to start, stop,
    restart, open the logs, or quit.

    All state changes go through omnivoice-service.ps1 rather than being
    reimplemented here -- the tray is a view, and a second copy of "how to stop
    the server" is how the two would come to disagree.

.EXAMPLE
    pwsh -File scripts\omnivoice-tray.ps1
    pwsh -File scripts\omnivoice-tray.ps1 -Install   # start it at logon
#>
[CmdletBinding()]
param(
    [int]$Port = 8000,
    [int]$PollSeconds = 3,
    # Register a logon shortcut for the tray itself and exit.
    [switch]$Install,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$ServiceScript = Join-Path $PSScriptRoot 'omnivoice-service.ps1'
if (-not (Test-Path -LiteralPath $ServiceScript)) {
    throw "omnivoice-service.ps1 not found beside this script"
}
$LogFile = Join-Path $env:LOCALAPPDATA 'omnivoice\server.log'
$StartupLink = Join-Path ([Environment]::GetFolderPath('Startup')) 'omnivoice-tray.lnk'

# --- install / uninstall the logon shortcut ----------------------------------

if ($Install) {
    # A Startup shortcut, not a task: this is a UI process with nothing to
    # supervise, and a shortcut is visible and deletable without a tool.
    $psExe = (Get-Process -Id $PID).Path
    # Through wscript, as with the service task: pwsh is console-subsystem and
    # flashes a window before -WindowStyle Hidden applies.
    $launcher = Join-Path $PSScriptRoot 'hidden-launch.vbs'
    if (-not (Test-Path -LiteralPath $launcher)) { throw "missing $launcher" }
    $wsh = New-Object -ComObject WScript.Shell
    $lnk = $wsh.CreateShortcut($StartupLink)
    $lnk.TargetPath = 'wscript.exe'
    $lnk.Arguments = "`"$launcher`" `"$psExe`" -NoProfile -ExecutionPolicy Bypass " +
                     "-File `"$PSCommandPath`" -Port $Port"
    $lnk.WorkingDirectory = $PSScriptRoot
    $lnk.Description = 'omnivoice tray control'
    $lnk.Save()
    Write-Host "omnivoice: tray will start at logon ($StartupLink)"
    exit 0
}
if ($Uninstall) {
    if (Test-Path -LiteralPath $StartupLink) {
        Remove-Item -LiteralPath $StartupLink -Force
        Write-Host "omnivoice: removed $StartupLink"
    }
    else { Write-Host "omnivoice: no tray shortcut installed" }
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- icons -------------------------------------------------------------------

function New-DotIcon {
    param([System.Drawing.Color]$Color)
    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush $Color
    $g.FillEllipse($brush, 2, 2, 12, 12)
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90, 0, 0, 0)), 1
    $g.DrawEllipse($pen, 2, 2, 12, 12)
    $brush.Dispose(); $pen.Dispose(); $g.Dispose()
    $handle = $bmp.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($handle)
    $bmp.Dispose()
    return $icon
}

$Icons = @{
    ready    = New-DotIcon ([System.Drawing.Color]::FromArgb(76, 175, 80))
    starting = New-DotIcon ([System.Drawing.Color]::FromArgb(255, 179, 0))
    down     = New-DotIcon ([System.Drawing.Color]::FromArgb(211, 47, 47))
}

# --- state -------------------------------------------------------------------

function Get-State {
    <#
        Health is the only question worth asking: a running process that cannot
        answer /health is down as far as anything using the voice is concerned.
    #>
    try {
        $r = Invoke-RestMethod "http://127.0.0.1:$Port/health" -TimeoutSec 2
        if ($r.status -eq 'ok') { return 'ready' }
        return 'starting'
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 503) { return 'starting' }
        return 'down'
    }
}

function Invoke-Service {
    param([string]$Action)
    # Out-of-process: the service script writes the same logs the supervisor
    # uses, and running it inline would inherit this process's WinForms state.
    Start-Process -FilePath (Get-Process -Id $PID).Path `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass',
                        '-File', $ServiceScript, $Action, '-Port', $Port) `
        -WindowStyle Hidden -Wait
}

# --- tray --------------------------------------------------------------------

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = $Icons.down
$notify.Text = 'omnivoice: checking...'
$notify.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$itemState = $menu.Items.Add('checking...')
$itemState.Enabled = $false
$null = $menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$itemStart = $menu.Items.Add('Start')
$itemStop = $menu.Items.Add('Stop')
$itemRestart = $menu.Items.Add('Restart')
$null = $menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$itemLogs = $menu.Items.Add('Open log folder')
$itemExit = $menu.Items.Add('Quit tray')
$notify.ContextMenuStrip = $menu

# Tooltip text is capped at 63 chars; assigning more throws inside a timer
# tick where nothing catches it, and the tray silently stops updating.
function Set-Tip {
    param([string]$Text)
    if ($Text.Length -gt 63) { $Text = $Text.Substring(0, 60) + '...' }
    $notify.Text = $Text
}

$script:Busy = $false

function Update-Ui {
    if ($script:Busy) { return }
    $state = Get-State
    $notify.Icon = $Icons[$state]
    switch ($state) {
        'ready' { Set-Tip 'omnivoice: ready'; $itemState.Text = 'ready' }
        'starting' { Set-Tip 'omnivoice: loading the model'; $itemState.Text = 'loading the model...' }
        'down' { Set-Tip 'omnivoice: not running'; $itemState.Text = 'not running' }
    }
    $itemStart.Enabled = ($state -eq 'down')
    $itemStop.Enabled = ($state -ne 'down')
    $itemRestart.Enabled = ($state -ne 'down')
}

function Run-Action {
    param([string]$Action, [string]$Pending)
    # The menu click runs on the UI thread, so the icon must be set BEFORE the
    # blocking call or the tray looks dead for the several seconds a start takes.
    $script:Busy = $true
    $notify.Icon = $Icons.starting
    Set-Tip "omnivoice: $Pending"
    $itemState.Text = "$Pending..."
    [System.Windows.Forms.Application]::DoEvents()
    try { Invoke-Service $Action } finally { $script:Busy = $false }
    Update-Ui
}

$itemStart.Add_Click({ Run-Action 'start' 'starting' })
$itemStop.Add_Click({ Run-Action 'stop' 'stopping' })
$itemRestart.Add_Click({ Run-Action 'restart' 'restarting' })
$itemLogs.Add_Click({ Start-Process (Split-Path -Parent $LogFile) })
$itemExit.Add_Click({
        $notify.Visible = $false
        [System.Windows.Forms.Application]::Exit()
    })
# Double-click is the conventional "show me the thing" gesture.
$notify.Add_DoubleClick({ Start-Process (Split-Path -Parent $LogFile) })

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $PollSeconds * 1000
$timer.Add_Tick({ Update-Ui })
$timer.Start()

Update-Ui

try {
    [System.Windows.Forms.Application]::Run()
}
finally {
    # Without this the icon lingers in the tray until the user hovers over it.
    $timer.Stop(); $timer.Dispose()
    $notify.Visible = $false
    $notify.Dispose()
    $menu.Dispose()
    foreach ($i in $Icons.Values) { $i.Dispose() }
}
