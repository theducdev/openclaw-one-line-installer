# Start-OpenClawGateway.ps1

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

# Check if WSL is running
$status = wsl -u $WslUser -- openclaw gateway status 2>&1

if ($status -match "running") {
    Write-Host "OpenClaw gateway is already running." -ForegroundColor Green
} else {
    Write-Host "Starting OpenClaw gateway..." -ForegroundColor Yellow
    wsl -u $WslUser -- openclaw gateway start
    Start-Sleep -Seconds 3
    wsl -u $WslUser -- openclaw gateway status
}
