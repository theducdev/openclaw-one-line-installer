# Create-OpenClawShortcuts.ps1

param(
    [string]$WslUser = ""
)

# Auto-detect or prompt for WSL username
if ([string]::IsNullOrEmpty($WslUser)) {
    $WslUser = (wsl -- whoami 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($WslUser)) {
        $WslUser = Read-Host "Enter your WSL username"
    }
    $WslUser = $WslUser.Trim()
}

$Desktop = [Environment]::GetFolderPath("Desktop")

# Get token from OpenClaw config
$token = wsl -u $WslUser -- bash -c "grep -o '""token"": ""[^""]*""' ~/.openclaw/openclaw.json | head -1 | cut -d'""' -f4"

# Web UI shortcut
@"
[InternetShortcut]
URL=http://127.0.0.1:18789/?token=$token
"@ | Out-File "$Desktop\OpenClaw-WebUI.url" -Encoding ASCII

# TUI launcher
@"
@echo off
wsl -u $WslUser -- openclaw tui
"@ | Out-File "$Desktop\OpenClaw-TUI.bat" -Encoding ASCII

# Status checker
@"
@echo off
wsl -u $WslUser -- openclaw gateway status
pause
"@ | Out-File "$Desktop\OpenClaw-Status.bat" -Encoding ASCII

# Gateway restart
@"
@echo off
wsl -u $WslUser -- openclaw gateway restart
echo Gateway restarted.
pause
"@ | Out-File "$Desktop\OpenClaw-Restart.bat" -Encoding ASCII

Write-Host "Desktop shortcuts created!" -ForegroundColor Green
