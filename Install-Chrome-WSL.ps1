# Install-Chrome-WSL.ps1

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

Write-Host "=== Installing Chrome in WSL ===" -ForegroundColor Cyan

Write-Host "Downloading Chrome..." -ForegroundColor Yellow
wsl -u $WslUser -- bash -c "cd /tmp && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

Write-Host "Installing Chrome..." -ForegroundColor Yellow
wsl -u $WslUser -- sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb 2>$null
wsl -u $WslUser -- sudo apt-get install -f -y

# Verify
$chromeVersion = wsl -u $WslUser -- google-chrome --version
Write-Host "`nChrome installed: $chromeVersion" -ForegroundColor Green

Write-Host @"
============================================
      Chrome Installation Complete!
============================================
Test it by running in WSL:
  google-chrome https://google.com
The browser window should appear on your Windows desktop (via WSLg).
"@ -ForegroundColor Cyan

pause
