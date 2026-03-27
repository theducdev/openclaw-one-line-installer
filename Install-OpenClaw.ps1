# Install-OpenClaw.ps1
# Run as Administrator

param(
    [string]$WslUser = ""
)

# Auto-detect or prompt for WSL username
if ([string]::IsNullOrEmpty($WslUser)) {
    $WslUser = (wsl -- whoami 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($WslUser)) {
        $WslUser = Read-Host "Enter your WSL username (the one you created during Ubuntu setup)"
    }
    $WslUser = $WslUser.Trim()
}

Write-Host "=== OpenClaw Automated Installer ===" -ForegroundColor Cyan
Write-Host "Using WSL user: $WslUser" -ForegroundColor Gray

# Check if WSL is installed
$wslCheck = wsl --list --quiet 2>$null
if (-not $wslCheck) {
    Write-Host "Installing WSL with Ubuntu..." -ForegroundColor Yellow
    wsl --install -d Ubuntu
    Write-Host "Please restart your computer and run this script again." -ForegroundColor Red
    exit
}

# Configure systemd
Write-Host "Configuring systemd..." -ForegroundColor Yellow
wsl -u root -e bash -c @'
cat > /etc/wsl.conf << 'EOF'
[boot]
systemd=true
[interop]
enabled=true
appendWindowsPath=true
EOF
'@

# Restart WSL
Write-Host "Restarting WSL..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep -Seconds 3

# Install Node.js
Write-Host "Installing Node.js 22..." -ForegroundColor Yellow
wsl -u root -- bash -c "curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs"

# Configure passwordless sudo
Write-Host "Configuring sudo..." -ForegroundColor Yellow
wsl -u root -- bash -c "echo '$WslUser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$WslUser"

# Install OpenClaw
Write-Host "Installing OpenClaw..." -ForegroundColor Yellow
wsl -u $WslUser -- bash -c "sudo npm install -g openclaw"

# Verify
$version = wsl -u $WslUser -- openclaw --version
Write-Host "OpenClaw installed: $version" -ForegroundColor Green

Write-Host @"
=== Installation Complete ===
Next steps:
1. Open WSL terminal: wsl
2. Run onboarding: openclaw onboard --install-daemon
3. Follow the interactive setup wizard
"@ -ForegroundColor Cyan
