# =============================================================
#   OpenClaw One-Line Installer for Windows - Techla Project
# =============================================================
#
# Usage (customer runs in PowerShell as Admin):
#
#   Set-ExecutionPolicy RemoteSigned -Scope Process -Force; iwr -useb https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.ps1 | iex
#
# Or with options:
#   $env:SKIP_CHROME="true"; iwr -useb https://URL/install.ps1 | iex
#   $env:API_KEY="sk-xxx"; iwr -useb https://URL/install.ps1 | iex
#
# =============================================================

$ErrorActionPreference = "Stop"

# --------------- Config ---------------
$SkipChrome = $env:SKIP_CHROME -eq "true"
$SkipShortcuts = $env:SKIP_SHORTCUTS -eq "true"
$ApiKey = $env:API_KEY

# --------------- Check Admin ---------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Please run PowerShell as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell -> Run as Administrator, then run the command again." -ForegroundColor Yellow
    exit 1
}

# --------------- Banner ---------------
Write-Host @"

   ___                    ____ _
  / _ \ _ __   ___ _ __  / ___| | __ ___      __
 | | | | '_ \ / _ \ '_ \| |   | |/ _`` \ \ /\ / /
 | |_| | |_) |  __/ | | | |___| | (_| |\ V  V /
  \___/| .__/ \___|_| |_|\____|_|\__,_| \_/\_/
       |_|

  One-Line Installer for Windows — Techla Project

"@ -ForegroundColor Cyan

# =============================================
# Step 1: WSL
# =============================================
Write-Host "[Step 1/6] Checking WSL..." -ForegroundColor Cyan

$wslCheck = wsl --list --quiet 2>$null
if (-not $wslCheck) {
    Write-Host "Installing WSL with Ubuntu..." -ForegroundColor Yellow
    wsl --install -d Ubuntu
    Write-Host ""
    Write-Host "=== WSL installed. Please RESTART your computer, then run this command again. ===" -ForegroundColor Red
    Write-Host ""
    exit 0
}
Write-Host "WSL is ready." -ForegroundColor Green

# --------------- Detect WSL user ---------------
$WslUser = (wsl -- whoami 2>$null).Trim()
if ([string]::IsNullOrEmpty($WslUser)) {
    $WslUser = Read-Host "Enter your WSL username"
    $WslUser = $WslUser.Trim()
}
Write-Host "WSL user: $WslUser" -ForegroundColor Gray

# =============================================
# Step 2: Configure systemd
# =============================================
Write-Host "`n[Step 2/6] Configuring WSL systemd..." -ForegroundColor Cyan

wsl -u root -e bash -c @'
cat > /etc/wsl.conf << 'EOF'
[boot]
systemd=true
[interop]
enabled=true
appendWindowsPath=true
EOF
'@

wsl --shutdown
Start-Sleep -Seconds 3
Write-Host "WSL configured." -ForegroundColor Green

# =============================================
# Step 3: Node.js
# =============================================
Write-Host "`n[Step 3/6] Installing Node.js 22..." -ForegroundColor Cyan

$nodeCheck = wsl -u $WslUser -- bash -c "node --version 2>/dev/null" 2>$null
if ($nodeCheck -match "v2[2-9]|v[3-9]") {
    Write-Host "Node.js already installed: $nodeCheck" -ForegroundColor Green
} else {
    wsl -u root -- bash -c "curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs"
    # Configure passwordless sudo
    wsl -u root -- bash -c "echo '$WslUser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$WslUser"
    Write-Host "Node.js installed." -ForegroundColor Green
}

# =============================================
# Step 4: OpenClaw
# =============================================
Write-Host "`n[Step 4/6] Installing OpenClaw..." -ForegroundColor Cyan

wsl -u $WslUser -- bash -c "sudo npm install -g openclaw"
$version = wsl -u $WslUser -- openclaw --version 2>$null
Write-Host "OpenClaw installed: $version" -ForegroundColor Green

# =============================================
# Step 5: Chrome (optional)
# =============================================
if (-not $SkipChrome) {
    Write-Host "`n[Step 5/6] Installing Chrome in WSL..." -ForegroundColor Cyan

    $chromeCheck = wsl -u $WslUser -- bash -c "command -v google-chrome 2>/dev/null"
    if ($chromeCheck) {
        Write-Host "Chrome already installed." -ForegroundColor Green
    } else {
        wsl -u $WslUser -- bash -c "cd /tmp && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt-get install -f -y && rm -f google-chrome-stable_current_amd64.deb"
        Write-Host "Chrome installed." -ForegroundColor Green
    }
} else {
    Write-Host "`n[Step 5/6] Skipping Chrome." -ForegroundColor Gray
}

# =============================================
# Step 6: Desktop shortcuts
# =============================================
if (-not $SkipShortcuts) {
    Write-Host "`n[Step 6/6] Creating desktop shortcuts..." -ForegroundColor Cyan

    $Desktop = [Environment]::GetFolderPath("Desktop")

    @"
@echo off
wsl -u $WslUser -- openclaw tui
"@ | Out-File "$Desktop\OpenClaw-TUI.bat" -Encoding ASCII

    @"
@echo off
wsl -u $WslUser -- openclaw gateway status
pause
"@ | Out-File "$Desktop\OpenClaw-Status.bat" -Encoding ASCII

    @"
@echo off
wsl -u $WslUser -- openclaw gateway restart
echo Gateway restarted.
pause
"@ | Out-File "$Desktop\OpenClaw-Restart.bat" -Encoding ASCII

    Write-Host "Shortcuts created on Desktop." -ForegroundColor Green
} else {
    Write-Host "`n[Step 6/6] Skipping shortcuts." -ForegroundColor Gray
}

# =============================================
# Step 7: API Key (if provided)
# =============================================
if (-not [string]::IsNullOrEmpty($ApiKey)) {
    Write-Host "`nConfiguring API key..." -ForegroundColor Cyan
    wsl -u $WslUser -- bash -c "mkdir -p ~/.openclaw && echo '{\"apiKey\": \"$ApiKey\"}' > ~/.openclaw/config.json"
    Write-Host "API key configured." -ForegroundColor Green
}

# =============================================
# Done
# =============================================
Write-Host @"

=============================================
      Setup Complete!
=============================================

What was installed:
  - WSL2 with Ubuntu
  - Node.js 22
  - OpenClaw $version
  - Chrome in WSL
  - Desktop shortcuts (TUI, Status, Restart)

Next step - run in WSL:
  wsl
  openclaw onboard --install-daemon

Shortcuts on Desktop:
  OpenClaw-TUI.bat     - Terminal UI
  OpenClaw-Status.bat  - Check status
  OpenClaw-Restart.bat - Restart gateway

=============================================
"@ -ForegroundColor Green
