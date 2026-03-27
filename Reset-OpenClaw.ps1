# Reset-OpenClaw.ps1
# WARNING: This deletes all OpenClaw data!

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

$confirm = Read-Host "This will DELETE all OpenClaw data. Type 'yes' to confirm"
if ($confirm -ne "yes") {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit
}

Write-Host "Stopping gateway..." -ForegroundColor Yellow
wsl -u $WslUser -- openclaw gateway stop 2>$null

Write-Host "Removing OpenClaw data..." -ForegroundColor Yellow
wsl -u $WslUser -- rm -rf ~/.openclaw

Write-Host "OpenClaw has been reset. Run 'openclaw onboard --install-daemon' to set up again." -ForegroundColor Green
