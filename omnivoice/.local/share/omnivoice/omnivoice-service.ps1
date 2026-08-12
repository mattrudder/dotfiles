<#
.SYNOPSIS
    Run omnivoice-server in the background, starting at logon.

.DESCRIPTION
    Registers a user-scope Scheduled Task that supervises the server, plus
    start/stop/status/logs commands so the GPU can be reclaimed on demand.

    The task runs `supervise`, not `start`: a task that launches and exits is
    reported SUCCEEDED, so its restart-on-failure never fires.

    The API key comes from the environment, never a command-line argument --
    argv is readable by any local process via Win32_Process.CommandLine.

    `say` and `voices` speak through the running server, so the same command
    that manages the GPU also uses it. A mini `say(1)`: text from arguments, a
    file, or stdin; audio played or written to -o.

.EXAMPLE
    .\scripts\omnivoice-service.ps1 install
    .\scripts\omnivoice-service.ps1 status
    .\scripts\omnivoice-service.ps1 stop      # free the VRAM

.EXAMPLE
    omnivoice say Deployment finished.
    omnivoice say -v juniper "Build failed on main."
    omnivoice say -f notes.txt -o notes.wav
    git log -1 --format=%s | omnivoice say
    omnivoice voices
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('help', 'install', 'uninstall', 'start', 'stop', 'restart', 'status', 'logs',
        'supervise', 'say', 'voices')]
    [string]$Command = 'status',

    # Fallback only, for before the binary has been cargo-installed.
    [string]$RepoRoot = ($env:OMNIVOICE_REPO ? $env:OMNIVOICE_REPO : 'D:\3p\omnivoice-rs'),

    [string]$Dtype = 'f16',
    [string]$VoicesFile,
    [int]$Port = 8000,
    [string]$ExtraArgs = '',

    # `logs` only: how many trailing lines to show.
    [int]$Tail = 40,

    # The aliases are load-bearing: PowerShell resolves a bare -v by PREFIX, and
    # -Verbose/-VoicesFile both match, so without an explicit alias it errors.
    [Alias('v')][string]$Voice,

    # Read the text from here instead of the command line. `-f -` means stdin,
    # as in say(1); stdin is also used when neither -f nor words are given.
    [Alias('f')][string]$InputFile,

    # Write the audio here instead of playing it -- say(1)'s -o, same silence.
    # The container comes from the extension, so `-o x.mp3` needs no -Format.
    [Alias('o')][string]$OutputFile,

    [ValidateRange(0.1, 5.0)]
    [double]$Speed = 1.0,

    # Voice-design prompt, e.g. "male, low pitch, middle-aged".
    [string]$Instruct,

    # Passed through, but it does NOT reproduce audio: same seed, voice and text
    # gave different lengths and 83% different bytes (measured).
    [uint64]$Seed,

    # No Position, deliberately: it would compete with $Command for token 0.
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Words
)

$ErrorActionPreference = 'Stop'

$TaskName = 'omnivoice-server'
$ScriptPath = $PSCommandPath
# Resolved every run so a later `cargo install` is picked up. Probed by
# path, not PATH: the task runs -NoProfile with the User environment.
$candidates = @(
    (Get-Command 'omnivoice-server' -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty Source),
    (Join-Path $HOME '.cargo\bin\omnivoice-server.exe'),
    (Join-Path $RepoRoot 'target\release\omnivoice-server.exe')
) | Where-Object { $_ }
$ServerExe = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
# Nothing installed anywhere yet: name the checkout, so the error says where it
# looked rather than reporting an empty path.
if (-not $ServerExe) { $ServerExe = Join-Path $RepoRoot 'target\release\omnivoice-server.exe' }
$installed = $ServerExe -ne (Join-Path $RepoRoot 'target\release\omnivoice-server.exe')

# Voices live in ~/.config/omnivoice (stowed from ~/.dotfiles-private).
# The .wav files must sit beside voices.toml -- ref_audio is relative.
if (-not $VoicesFile) { $VoicesFile = Join-Path $HOME '.config\omnivoice\voices.toml' }

# Start-Process throws on a missing working directory, so fall back to $HOME
# once the checkout is gone.
$WorkDir = if (Test-Path -LiteralPath $RepoRoot) { $RepoRoot } else { $HOME }

$LogDir = Join-Path $env:LOCALAPPDATA 'omnivoice'
$LogFile = Join-Path $LogDir 'server.log'
$ErrFile = Join-Path $LogDir 'server.err.log'
# Its own file: -RedirectStandardOutput truncates server.log on every start,
# which would erase the restart history this exists to produce.
$SuperFile = Join-Path $LogDir 'supervisor.log'
$MaxLogBytes = 5MB

function Fail { param([string]$Message) [Console]::Error.WriteLine("omnivoice: $Message"); exit 1 }
function Say { param([string]$Message) Write-Host "omnivoice: $Message" }

function Get-ServerProcess {
    # By image path, not name: another checkout's server is a different thing.
    Get-CimInstance Win32_Process -Filter "Name='omnivoice-server.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.ExecutablePath -eq $ServerExe }
}

function Get-SupervisorProcess {
    # Orphaned from the task by design: wscript returns at once, so the task
    # reads Ready and Stop-ScheduledTask cannot reach the supervisor.
    # Match the script path immediately followed by the subcommand, and never
    # self: a looser match killed the very shell that invoked it.
    Get-CimInstance Win32_Process -Filter "Name='pwsh.exe' OR Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object {
            $_.ProcessId -ne $PID -and $_.CommandLine -and (
                $_.CommandLine -like "*`"$ScriptPath`" supervise*" -or
                $_.CommandLine -like "*$ScriptPath supervise*")
        }
}

function Get-PortOwner {
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $conn) { return $null }
    Get-CimInstance Win32_Process -Filter "ProcessId=$($conn.OwningProcess)" -ErrorAction SilentlyContinue
}

function Test-Health {
    try {
        $r = Invoke-RestMethod "http://127.0.0.1:$Port/health" -TimeoutSec 3
        return $r.status
    }
    catch {
        # 503 is a real answer: the runtime is still loading. Distinguish it
        # from "nothing is listening", because they need opposite reactions.
        if ($_.Exception.Response.StatusCode.value__ -eq 503) { return 'starting' }
        return $null
    }
}

function Rotate-Log {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    if ((Get-Item -LiteralPath $Path).Length -lt $MaxLogBytes) { return }
    Move-Item -LiteralPath $Path -Destination "$Path.1" -Force -ErrorAction SilentlyContinue
}

function Get-ServerArguments {
    $serverArgs = @('--voices', $VoicesFile, '--dtype', $Dtype, '--port', $Port)
    if ($ExtraArgs) { $serverArgs += $ExtraArgs.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) }
    return $serverArgs
}

# --- supervise: what the scheduled task actually runs ------------------------

function Invoke-Supervise {
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    if (-not (Test-Path -LiteralPath $ServerExe)) {
        Add-Content -LiteralPath $SuperFile -Value "$(Get-Date -Format s) no server binary at $ServerExe"
        exit 1
    }
    if (-not $env:OMNIVOICE_API_KEY) {
        # A missing key is not a crash to retry: the server exits immediately
        # on validate(), so looping would spin. Say why, once, and stop.
        Add-Content -LiteralPath $SuperFile -Value ("$(Get-Date -Format s) OMNIVOICE_API_KEY is not set in " +
            "this task's environment. setx OMNIVOICE_API_KEY <key>, then log out and back in.")
        exit 1
    }

    $serverArgs = Get-ServerArguments
    # Rapid-failure cap: a server dying this fast is failing at startup, and
    # retrying it just fills the disk with the same error.
    $rapidWindow = 15
    $rapidLimit = 5
    $rapidCount = 0

    while ($true) {
        Rotate-Log $LogFile
        Rotate-Log $ErrFile
        Rotate-Log $SuperFile
        Add-Content -LiteralPath $SuperFile -Value "$(Get-Date -Format s) starting: $ServerExe $($serverArgs -join ' ')"
        $started = Get-Date

        $proc = Start-Process -FilePath $ServerExe -ArgumentList $serverArgs `
            -WorkingDirectory $WorkDir -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $LogFile -RedirectStandardError $ErrFile
        $proc.WaitForExit()

        $ran = (Get-Date) - $started
        Add-Content -LiteralPath $SuperFile -Value ("$(Get-Date -Format s) exited code $($proc.ExitCode) " +
            "after $([int]$ran.TotalSeconds)s")

        if ($ran.TotalSeconds -lt $rapidWindow) {
            $rapidCount++
            if ($rapidCount -ge $rapidLimit) {
                Add-Content -LiteralPath $SuperFile -Value ("$(Get-Date -Format s) gave up after $rapidLimit " +
                    "starts in under ${rapidWindow}s each; this is a startup failure, not a crash. " +
                    "See server.err.log for why.")
                exit 1
            }
        }
        else {
            $rapidCount = 0
        }
        Start-Sleep -Seconds ([Math]::Min(30, 2 * [Math]::Max(1, $rapidCount)))
    }
}

# --- commands ----------------------------------------------------------------

function Test-Shim {
    # The shims ship in this stow package; install.ps1 places them, not this.
    $found = Get-Command omnivoice -ErrorAction SilentlyContinue
    if ($found) { Say "shim     : $($found.Source)"; return }
    Write-Warning ("``omnivoice`` is not on PATH. It ships in this stow package; " +
        "run: rstow -s ~/.dotfiles/omnivoice -t ~   (no -f)")
}


function Invoke-Install {
    if (-not (Test-Path -LiteralPath $ServerExe)) {
        # ${RepoRoot} before a colon -- PowerShell reads $x: as a drive. --branch
        # is required; the fork's default branch has no voices route.
        Fail ("no omnivoice-server. Install it so it lands on PATH and no checkout is needed:`n" +
              "  cargo install --git https://github.com/mattrudder/omnivoice-rs " +
              "--branch mattrudder/voice-profiles omnivoice-server --features cuda`n" +
              "or build the checkout at ${RepoRoot}: " +
              "cargo build --release -p omnivoice-server --features cuda")
    }
    if (-not (Test-Path -LiteralPath $VoicesFile)) { Fail "no voices config at $VoicesFile" }
    if (-not [System.Environment]::GetEnvironmentVariable('OMNIVOICE_API_KEY', 'User')) {
        # Warn rather than refuse: the variable is Matt's to set, and install is
        # still useful ahead of it.
        Write-Warning ("OMNIVOICE_API_KEY is not set at User scope. The task inherits the USER " +
            "environment, so set it with `setx OMNIVOICE_API_KEY <key>` or the server will not start.")
    }

    $psExe = (Get-Process -Id $PID).Path   # the same host running this script

    # Launched via wscript: pwsh is console-subsystem and flashes a window before
    # -WindowStyle Hidden applies. Children inherit the absence of a console.
    $launcher = Join-Path $PSScriptRoot 'hidden-launch.vbs'
    if (-not (Test-Path -LiteralPath $launcher)) { Fail "missing $launcher" }
    $argument = "`"$launcher`" `"$psExe`" -NoProfile -NonInteractive -ExecutionPolicy Bypass " +
                "-File `"$PSCommandPath`" supervise -RepoRoot `"$RepoRoot`" -Dtype $Dtype -Port $Port"
    $action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument $argument -WorkingDirectory $WorkDir
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -MultipleInstances IgnoreNew `
        -ExecutionTimeLimit ([TimeSpan]::Zero)   # unlimited; it is a server

    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
        -Settings $settings -Force `
        -Description "Supervises omnivoice-server for vox. Managed by scripts/omnivoice-service.ps1." | Out-Null

    Test-Shim
    Say "installed task '$TaskName' (starts at logon)"
    Say ("  binary : $ServerExe" + $(if ($installed) { " (installed)" } else { " (from the checkout at $RepoRoot)" }))
    Say "  voices : $VoicesFile"
    Say "  logs   : $LogFile"
    Say "run 'omnivoice start' to start it now (from any directory)"
}

function Invoke-Uninstall {
    Invoke-Stop
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Say "removed task '$TaskName'"
    }
    else { Say "no task '$TaskName' registered" }
}

function Invoke-Start {
    $owner = Get-PortOwner
    if ($owner) {
        if ($owner.ExecutablePath -eq $ServerExe) { Say "already running (pid $($owner.ProcessId))"; return }
        Fail "port $Port is held by $($owner.Name) (pid $($owner.ProcessId)); stop it first"
    }
    if (-not (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {
        Fail "task '$TaskName' is not installed; run: omnivoice install"
    }
    # The task cannot refuse a duplicate: it reads Ready the instant wscript
    # returns, so a second supervisor would race the first for the port.
    $sups = @(Get-SupervisorProcess)
    if ($sups.Count) {
        Say "a supervisor is already running (pid $($sups[0].ProcessId)); it will bring the server back on its own"
        return
    }
    Start-ScheduledTask -TaskName $TaskName
    Say "started; the model takes ~20-30s to load. Watch with: .\scripts\omnivoice-service.ps1 status"
}

function Invoke-Stop {
    # Supervisor first, by pid: killing the server while it lives just makes it
    # start another, and Stop-ScheduledTask does not reach it.
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        try { Stop-ScheduledTask -TaskName $TaskName -ErrorAction Stop } catch { }
    }
    $sups = @(Get-SupervisorProcess)
    foreach ($p in $sups) {
        try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } catch { }
    }
    $procs = @(Get-ServerProcess)
    foreach ($p in $procs) {
        try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } catch { }
    }
    if ($sups.Count -or $procs.Count) {
        Say "stopped $($sups.Count) supervisor(s) and $($procs.Count) server process(es)"
    }
    else { Say "not running" }
}

function Invoke-Status {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    # Report the supervisor, not the task State: the latter is always Ready.
    Say ("task     : " + $(if ($task) { "installed" } else { "not installed" }))
    $sups = @(Get-SupervisorProcess)
    Say ("supervisor: " + $(if ($sups.Count -eq 1) { "pid $($sups[0].ProcessId)" }
                            elseif ($sups.Count) { "$($sups.Count) RUNNING - they will race; run 'omnivoice restart'" }
                            else { "none (nothing will restart a crash)" }))

    $proc = Get-ServerProcess | Select-Object -First 1
    if ($proc) {
        $started = $proc.CreationDate
        Say "process  : pid $($proc.ProcessId), up since $started"
    }
    else { Say "process  : not running" }

    $owner = Get-PortOwner
    if ($owner -and $owner.ExecutablePath -ne $ServerExe) {
        Say "port $Port : held by $($owner.Name) (pid $($owner.ProcessId)) -- NOT this build"
    }

    $health = Test-Health
    Say ("health   : " + $(switch ($health) {
        'ok' { "ready" }
        'starting' { "loading the model (503)" }
        default { "unreachable on port $Port" }
    }))

    if ($health -eq 'ok') {
        try {
            $key = $env:OMNIVOICE_API_KEY
            if ($key) {
                $v = Invoke-RestMethod "http://127.0.0.1:$Port/v1/audio/voices" -Headers @{Authorization = "Bearer $key"} -TimeoutSec 5
                Say "voices   : $($v.data.id -join ', ')  (default $($v.default), $($v.sample_rate) Hz)"
            }
            else { Say "voices   : OMNIVOICE_API_KEY not set in this shell, cannot list" }
        }
        catch { Say "voices   : $($_.Exception.Message)" }
    }
    Say "logs     : $LogFile"
    if (Test-Path -LiteralPath $SuperFile) {
        $restarts = @(Select-String -LiteralPath $SuperFile -Pattern '^\S+ starting:' -ErrorAction SilentlyContinue).Count
        Say "restarts : $restarts recorded in $SuperFile"
    }
}

function Invoke-Logs {
    # Supervisor first: restarts are the thing you came to find out about, and
    # server.log only ever holds the CURRENT server's output.
    if (Test-Path -LiteralPath $SuperFile) {
        Write-Host "--- supervisor ($SuperFile) ---"
        Get-Content -LiteralPath $SuperFile -Tail $Tail
        Write-Host ""
    }
    if (-not (Test-Path -LiteralPath $LogFile)) { Say "no server log yet at $LogFile"; return }
    Write-Host "--- server (current run only; redirect truncates on each start) ---"
    Get-Content -LiteralPath $LogFile -Tail $Tail
    if ((Test-Path -LiteralPath $ErrFile) -and (Get-Item -LiteralPath $ErrFile).Length -gt 0) {
        Write-Host "`n--- stderr ---"
        Get-Content -LiteralPath $ErrFile -Tail $Tail
    }
}

function Invoke-Help {
    # Hand-written: Get-Help would show script parameters, not subcommands.
    # Keep in step with the ValidateSet on $Command.
    @"
omnivoice - manage and use the local TTS server

usage: omnivoice <command> [options]

speech
  say [text...]        speak text, or write it to a file with -o
  voices               list the voices the running server offers

  -v, -Voice <name>    voice to use; validated against the server
  -f, -InputFile <p>   read the text from a file ('-' for stdin)
  -o, -OutputFile <p>  write audio instead of playing it; .wav .mp3 .pcm
      -Speed <n>       0.1-5.0, default 1.0
      -Instruct <s>    voice-design prompt, e.g. "male, low pitch"
      -Seed <n>        seed the sampler (does NOT reproduce audio; measured)

  With no text and no -f, stdin is read when it is piped.

service
  status               task, supervisor, process, health, voices  (default)
  start | stop         start it, or stop it to free the VRAM
  restart              stop, wait, start
  logs [-Tail n]       supervisor history, then the current server's output
  install              register the logon task that supervises the server
  uninstall            stop everything and remove the task
  help                 this

examples
  omnivoice say Deployment finished.
  omnivoice say -v juniper "Build failed on main."
  omnivoice say -f notes.txt -o notes.wav
  git log -1 --format=%s | omnivoice say
"@
}

# --- say ---------------------------------------------------------------------

function Get-ApiKey {
    $key = $env:OMNIVOICE_API_KEY
    if (-not $key) {
        Fail ("OMNIVOICE_API_KEY is not set in this shell. The server takes the same value; " +
            "set it with 'setx OMNIVOICE_API_KEY <key>' and open a new shell.")
    }
    return $key
}

function Get-VoiceCatalog {
    # The server, not voices.toml, is the authority on what voices exist.
    # Loading / not running / bad key need separate messages.
    $key = Get-ApiKey
    try {
        return Invoke-RestMethod "http://127.0.0.1:$Port/v1/audio/voices" `
            -Headers @{ Authorization = "Bearer $key" } -TimeoutSec 10
    }
    catch {
        switch ($_.Exception.Response.StatusCode.value__) {
            503 { Fail "the server is still loading the model; try again in a few seconds" }
            401 { Fail "the server rejected OMNIVOICE_API_KEY (401). It must match the key the server was started with." }
            default {
                # A refused connection arrives with an empty Message, so the
                # usual "(reason)" tail would render as an empty "()".
                $why = $_.Exception.Message
                $why = if ($why) { " ($why)" } else { '' }
                Fail "no server on port $Port$why. Start it with: omnivoice start"
            }
        }
    }
}

function New-PlayableWav {
    # The server emits float32 WAVE_FORMAT_EXTENSIBLE, which SoundPlayer
    # refuses; rewrite it as canonical 16-bit PCM.
    param([string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 12 -or [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4) -ne 'RIFF') {
        throw "not a RIFF file: $Path"
    }

    $fmtOffset = -1; $dataOffset = -1; $dataSize = 0
    $offset = 12
    while ($offset + 8 -le $bytes.Length) {
        $id = [System.Text.Encoding]::ASCII.GetString($bytes, $offset, 4)
        $size = [System.BitConverter]::ToUInt32($bytes, $offset + 4)
        $payload = $offset + 8
        if ($id -eq 'fmt ') { $fmtOffset = $payload }
        elseif ($id -eq 'data') { $dataOffset = $payload; $dataSize = [int][Math]::Min($size, $bytes.Length - $payload) }
        # RIFF chunks are word-aligned.
        $offset = $payload + $size + ($size % 2)
    }
    if ($fmtOffset -lt 0 -or $dataOffset -lt 0) { throw "malformed WAV (missing fmt/data): $Path" }

    $tag = [System.BitConverter]::ToUInt16($bytes, $fmtOffset)
    $channels = [System.BitConverter]::ToUInt16($bytes, $fmtOffset + 2)
    $rate = [System.BitConverter]::ToUInt32($bytes, $fmtOffset + 4)
    $bits = [System.BitConverter]::ToUInt16($bytes, $fmtOffset + 14)
    if ($tag -eq 0xFFFE) {
        # WAVE_FORMAT_EXTENSIBLE: the real format tag is the first field of the
        # SubFormat GUID at fmt+24.
        $tag = [System.BitConverter]::ToUInt16($bytes, $fmtOffset + 24)
    }

    if ($tag -eq 1 -and $bits -eq 16) { return $Path }
    if ($tag -ne 3 -or $bits -ne 32) { throw "unsupported WAV format (tag=$tag bits=$bits)" }

    $sampleCount = [int]($dataSize / 4)
    # Fill an int16[] and BlockCopy once; GetBytes() per sample would allocate a
    # throwaway array for every sample, which a minute of speech makes felt.
    $samples = New-Object int16[] $sampleCount
    for ($i = 0; $i -lt $sampleCount; $i++) {
        $f = [System.BitConverter]::ToSingle($bytes, $dataOffset + ($i * 4))
        if ($f -gt 1.0) { $f = 1.0 } elseif ($f -lt -1.0) { $f = -1.0 }
        $samples[$i] = [int16][Math]::Round($f * 32767)
    }
    $pcm = New-Object byte[] ($sampleCount * 2)
    [System.Buffer]::BlockCopy($samples, 0, $pcm, 0, $pcm.Length)

    $out = Join-Path ([System.IO.Path]::GetTempPath()) ("omnivoice-play-{0}.wav" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
    $writer = New-Object System.IO.BinaryWriter([System.IO.File]::Create($out))
    try {
        $blockAlign = $channels * 2
        $writer.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF'))
        $writer.Write([uint32](36 + $pcm.Length))
        $writer.Write([System.Text.Encoding]::ASCII.GetBytes('WAVEfmt '))
        $writer.Write([uint32]16)
        $writer.Write([uint16]1)
        $writer.Write([uint16]$channels)
        $writer.Write([uint32]$rate)
        $writer.Write([uint32]($rate * $blockAlign))
        $writer.Write([uint16]$blockAlign)
        $writer.Write([uint16]16)
        $writer.Write([System.Text.Encoding]::ASCII.GetBytes('data'))
        $writer.Write([uint32]$pcm.Length)
        $writer.Write($pcm)
    }
    finally { $writer.Dispose() }
    return $out
}

function Invoke-Voices {
    $catalog = Get-VoiceCatalog
    if (-not $catalog.data -or $catalog.data.Count -eq 0) {
        Say "the server has no voices configured (started without --voices)"
        return
    }
    # Write-Host for the list too: bare strings go to the pipeline while Say goes
    # to the host, which would split the heading from the voices.
    Say "voices on port $Port ($($catalog.sample_rate) Hz)"
    foreach ($entry in $catalog.data) {
        $marker = if ($entry.id -eq $catalog.default) { ' (default)' } else { '' }
        Write-Host ("  {0,-16} {1}{2}" -f $entry.id, $entry.type, $marker)
    }
}

function Get-SayText {
    # say(1)'s three sources, same precedence: -f wins, then the words on the
    # command line, then stdin.
    $usage = "nothing to say. Usage: omnivoice say [-v voice] [-f in.txt] [-o out.wav] [text...]"

    if ($InputFile -and $InputFile -ne '-') {
        if (-not (Test-Path -LiteralPath $InputFile)) { Fail "no such input file: $InputFile" }
        $fromFile = [System.IO.File]::ReadAllText($InputFile)
        # Named a file and got nothing: that is a wrong file, not a usage
        # mistake, so name the file rather than reprinting the usage line.
        if (-not $fromFile.Trim()) { Fail "input file is empty: $InputFile" }
        return $fromFile
    }
    if ($Words -and ($Words -join ' ').Trim()) { return ($Words -join ' ') }

    # Stdin last and only when redirected, so an interactive `say` with no
    # text reports usage instead of blocking on a terminal read.
    if ($InputFile -eq '-' -or [Console]::IsInputRedirected) {
        $fromStdin = [Console]::In.ReadToEnd()
        if ($fromStdin.Trim()) { return $fromStdin }
    }
    Fail $usage
}

function Invoke-Say {
    $key = Get-ApiKey

    # `-v ?` is say(1)'s spelling, but `?` globs in sh -- it silently became
    # `-v a` beside a one-character file, so `omnivoice voices` also exists.
    if ($Voice -eq '?') { Invoke-Voices; return }

    $text = (Get-SayText).Trim()

    # Container comes from the extension, and is resolved before the server
    # is consulted so a typo needs no running GPU to report.
    $format = 'wav'
    if ($OutputFile) {
        $format = switch ([System.IO.Path]::GetExtension($OutputFile).ToLowerInvariant()) {
            '.wav' { 'wav' }
            '.mp3' { 'mp3' }
            '.pcm' { 'pcm' }
            default { Fail "cannot tell the format from '$OutputFile'. Use .wav, .mp3, or .pcm." }
        }
    }

    # One request to the server, reused for validation and for the error text,
    # so a typo names the voices that actually exist right now.
    $catalog = Get-VoiceCatalog
    if ($Voice) {
        $match = $catalog.data | Where-Object { $_.id -eq $Voice } | Select-Object -First 1
        if (-not $match) {
            # The server silently falls back to default_voice on an unknown name, so a
            # typo would synthesize in the wrong voice and look like it worked.
            $known = ($catalog.data.id | Sort-Object) -join ', '
            Fail "unknown voice '$Voice'. The server offers: $known"
        }
        if ($Instruct -and $match.type -eq 'design') {
            Fail ("-Voice '$Voice' is a design voice and carries its own instruct, which the server " +
                "applies instead of -Instruct. Pick one.")
        }
    }

    # "default" rather than the served model id, so a custom --served-model-id
    # does not break this command.
    $payload = [ordered]@{
        model           = 'default'
        input           = $text
        response_format = $format
        speed           = $Speed
    }
    if ($Voice) { $payload.voice = $Voice }
    if ($Instruct) { $payload.instruct = $Instruct }
    if ($PSBoundParameters.ContainsKey('Seed')) { $payload.seed = $Seed }

    $body = [System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Compress -Depth 4))

    $isTemp = -not $OutputFile
    $target = if ($isTemp) {
        Join-Path ([System.IO.Path]::GetTempPath()) ("omnivoice-say-{0}.wav" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
    }
    else { $OutputFile }

    Write-Verbose "POST /v1/audio/speech ($($body.Length) bytes, format=$format)"
    try {
        # Matches the server's own request timeout; the client default would cut off
        # long synthesis and report it as a network error.
        Invoke-WebRequest -Uri "http://127.0.0.1:$Port/v1/audio/speech" `
            -Method Post `
            -Headers @{ Authorization = "Bearer $key" } `
            -ContentType 'application/json' `
            -Body $body `
            -TimeoutSec 300 `
            -OutFile $target | Out-Null
    }
    catch {
        # The server explains itself in a JSON body; surface that, not the status.
        $detail = $_.ErrorDetails.Message
        if (-not $detail -and $_.Exception.Response) {
            try { $detail = (New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() }
            catch { }
        }
        if ($isTemp -and (Test-Path -LiteralPath $target)) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
        if ($detail) { Fail "synthesis failed: $detail" } else { Fail "synthesis failed: $_" }
    }

    # -o means "write it", and say(1) stays silent when it writes. Scripts that
    # want the path already know it; scripts that want audio did not pass -o.
    if ($OutputFile) { return }

    try {
        $playable = New-PlayableWav -Path $target
        try {
            $player = New-Object System.Media.SoundPlayer $playable
            $player.PlaySync()
        }
        finally {
            if ($playable -ne $target) { Remove-Item -LiteralPath $playable -Force -ErrorAction SilentlyContinue }
        }
    }
    finally {
        Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    }
}

# --help and -h match no parameter, so they fall into $Words and would
# print a status report instead. Excluded for `say`, where $Words is prose.
if ($Command -ne 'say' -and $Words) {
    if ($Words | Where-Object { $_ -in @('-h', '--help', '-help', '--h', '/?', 'help') }) {
        Invoke-Help
        exit 0
    }
}

switch ($Command) {
    'help' { Invoke-Help }
    'install' { Invoke-Install }
    'uninstall' { Invoke-Uninstall }
    'start' { Invoke-Start }
    'stop' { Invoke-Stop }
    'restart' { Invoke-Stop; Start-Sleep -Seconds 2; Invoke-Start }
    'status' { Invoke-Status }
    'logs' { Invoke-Logs }
    'supervise' { Invoke-Supervise }
    'say' { Invoke-Say }
    'voices' { Invoke-Voices }
}
