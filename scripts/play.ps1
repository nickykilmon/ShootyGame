# One-button launcher: starts the game server, starts the Cloudflare tunnel,
# reads the public URL out of the tunnel's own log, writes it into server.txt,
# and pushes that to GitHub so the web build picks it up automatically.
#
# Edit the two paths below if Godot or the project ever move.

$ErrorActionPreference = "Stop"

$Godot   = "C:\Users\nrkil\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$Project = "C:\Users\nrkil\Downloads\MultiplayerFPSTutorial-main\MultiplayerFPSTutorial-main"

# Fill this in with your Netlify site so PLAY.bat can open it for you automatically.
# Leave blank to skip auto-open.
$NetlifyUrl = ""

$GodotProcNames = @("Godot_v4.7.2-stable_win64_console", "Godot_v4.7.2-stable_win64")
$LogFile = Join-Path $env:TEMP "shootygame_tunnel_log.txt"

function Say($msg, $color = "Cyan") { Write-Host $msg -ForegroundColor $color }

# ---- sanity checks ---------------------------------------------------------
if (-not (Test-Path $Godot)) {
    Say "Can't find Godot at:`n  $Godot`nEdit the `$Godot line at the top of scripts\play.ps1." "Red"
    Read-Host "Press Enter to close"
    exit 1
}
if (-not (Test-Path (Join-Path $Project "project.godot"))) {
    Say "That PROJECT path doesn't look like the game folder:`n  $Project" "Red"
    Read-Host "Press Enter to close"
    exit 1
}
$cloudflaredOk = $true
try { cloudflared --version | Out-Null } catch { $cloudflaredOk = $false }
if (-not $cloudflaredOk) {
    Say "cloudflared isn't installed / not on PATH. Run:  winget install --id Cloudflare.cloudflared" "Red"
    Say "Then close and reopen PowerShell before trying again." "Red"
    Read-Host "Press Enter to close"
    exit 1
}

# ---- clean up any previous run ---------------------------------------------
Say "Stopping any server/tunnel already running..."
Get-Process -Name ($GodotProcNames + @("cloudflared")) -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Remove-Item $LogFile -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# ---- start the game server ---------------------------------------------------
Say "Starting the game server..."
Start-Process -FilePath $Godot -ArgumentList @("--headless", "--path", $Project, "--", "--server") -WindowStyle Minimized

# ---- start the tunnel (output captured to a log file we can read) ------------
Say "Starting the Cloudflare tunnel..."
$cmdLine = "/c cloudflared tunnel --url http://localhost:9999 > `"$LogFile`" 2>&1"
Start-Process -FilePath "cmd.exe" -ArgumentList $cmdLine -WindowStyle Hidden

Say "Waiting for the tunnel address" "Cyan"
$publicUrl = $null
for ($i = 0; $i -lt 45; $i++) {
    Start-Sleep -Seconds 1
    Write-Host "." -NoNewline
    if (Test-Path $LogFile) {
        $content = Get-Content $LogFile -Raw -ErrorAction SilentlyContinue
        if ($content -match "https://([a-zA-Z0-9-]+\.trycloudflare\.com)") {
            $publicUrl = "wss://" + $matches[1]
            break
        }
    }
}
Write-Host ""

if (-not $publicUrl) {
    Say "Couldn't find the tunnel address after 45 seconds. Open this log and check for errors:" "Red"
    Say "  $LogFile" "Red"
    Read-Host "Press Enter to close"
    exit 1
}

Say "Tunnel is up: $publicUrl" "Green"
Start-Sleep -Seconds 2   # let Cloudflare finish propagating the quick tunnel

# ---- write server.txt --------------------------------------------------------
Say "Updating server.txt..."
Set-Location $Project
$lines = Get-Content "server.txt"
$lines[0] = $publicUrl
# ASCII, not utf8 -> Windows PowerShell's utf8 encoder adds a BOM, which would
# make the game's "starts with wss://" check fail on the first line.
Set-Content -Path "server.txt" -Value $lines -Encoding ascii

# ---- commit + push -----------------------------------------------------------
$gitOk = $true
try { git --version | Out-Null } catch { $gitOk = $false }

if ($gitOk) {
    Say "Pushing the new address to GitHub..."
    git add server.txt | Out-Null
    $staged = git diff --cached --name-only
    if ($staged) {
        git commit -m "auto: update server url" | Out-Null
        $pushOutput = git push 2>&1
        Write-Host $pushOutput
        if ($LASTEXITCODE -ne 0) {
            Say "Push failed. Open GitHub Desktop and click 'Push origin' manually." "Yellow"
        } else {
            Say "Pushed." "Green"
        }
    } else {
        Say "server.txt already had this address - nothing to push." "Yellow"
    }
} else {
    Say "git isn't on PATH. Open GitHub Desktop, you should see server.txt changed - Commit to main, then Push." "Yellow"
}

# ---- done ---------------------------------------------------------------------
Write-Host ""
Say "============================================================" "Green"
Say " SERVER IS LIVE" "Green"
Say " Give it 60-90 seconds, then have everyone open your Netlify link and Join." "Green"
Say "============================================================" "Green"
Write-Host ""

if ($NetlifyUrl -ne "") {
    Start-Sleep -Seconds 2
    Start-Process $NetlifyUrl
}

Say "Leave this window open. Press Enter here at any time to STOP the server + tunnel." "Cyan"
Read-Host
Get-Process -Name ($GodotProcNames + @("cloudflared")) -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Say "Stopped." "Green"
Start-Sleep -Seconds 1
