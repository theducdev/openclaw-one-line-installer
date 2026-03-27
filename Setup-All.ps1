# Setup-All.ps1
# Master script - runs full OpenClaw setup for customer laptops
# Run as Administrator: Right-click PowerShell -> Run as Administrator

param(
    [string]$WslUser = "",
    [switch]$SkipChrome = $false,
    [switch]$SkipShortcuts = $false
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host @"
=============================================
   OpenClaw Quick Setup - Techla Project
=============================================
"@ -ForegroundColor Cyan

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Please run this script as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell -> Run as Administrator" -ForegroundColor Yellow
    pause
    exit 1
}

# Set execution policy for this session
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# Step 1: Install OpenClaw
Write-Host "`n[Step 1/3] Installing OpenClaw..." -ForegroundColor Cyan
& "$ScriptDir\Install-OpenClaw.ps1" -WslUser $WslUser

# Step 2: Install Chrome in WSL (optional)
if (-not $SkipChrome) {
    Write-Host "`n[Step 2/3] Installing Chrome in WSL..." -ForegroundColor Cyan
    & "$ScriptDir\Install-Chrome-WSL.ps1" -WslUser $WslUser
} else {
    Write-Host "`n[Step 2/3] Skipping Chrome install." -ForegroundColor Gray
}

# Step 3: Create desktop shortcuts
if (-not $SkipShortcuts) {
    Write-Host "`n[Step 3/3] Creating desktop shortcuts..." -ForegroundColor Cyan
    & "$ScriptDir\Create-OpenClawShortcuts.ps1" -WslUser $WslUser
} else {
    Write-Host "`n[Step 3/3] Skipping shortcuts." -ForegroundColor Gray
}

Write-Host @"

=============================================
      Setup Complete!
=============================================

What was installed:
  - WSL2 with Ubuntu
  - Node.js 22
  - OpenClaw (latest)
  - Chrome in WSL (for web scraping)
  - Desktop shortcuts

Next steps for the customer:
  1. Open WSL terminal (type 'wsl' in Start menu)
  2. Run: openclaw onboard --install-daemon
  3. Follow the setup wizard
  4. Use the desktop shortcuts to manage OpenClaw

Shortcuts on Desktop:
  - OpenClaw-WebUI.url   -> Opens web interface
  - OpenClaw-TUI.bat     -> Opens terminal UI
  - OpenClaw-Status.bat  -> Check gateway status
  - OpenClaw-Restart.bat -> Restart gateway

=============================================
"@ -ForegroundColor Green

pause
