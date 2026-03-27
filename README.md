# openclaw-one-line-installer

One command to install OpenClaw on any customer laptop. Supports **macOS**, **Ubuntu/Debian**, **Fedora/RHEL**, **Arch Linux**, and **Windows**.

## Quick Start

### macOS / Linux / Ubuntu

```bash
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash
```

### Windows (PowerShell as Admin)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force
.\Setup-All.ps1
```

## Options

```bash
# Skip Chrome install
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash -s -- --skip-chrome

# Pre-configure API key
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash -s -- --api-key=sk-xxxxx

# Skip interactive onboarding
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash -s -- --skip-onboard

# Combine options
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash -s -- --skip-chrome --api-key=sk-xxxxx
```

## What Gets Installed

| Component | Purpose |
|-----------|---------|
| Node.js 22 | Runtime for OpenClaw |
| OpenClaw | AI assistant platform |
| Google Chrome | Web scraping support |

## How It Works

The installer auto-detects the OS and package manager:

| OS | Package Manager |
|----|----------------|
| macOS | Homebrew |
| Ubuntu / Debian | apt |
| Fedora / RHEL / CentOS | yum / dnf |
| Arch Linux | pacman |
| Windows | WSL2 + PowerShell |

## Project Structure

```
├── install.sh                  # One-line installer (macOS/Linux)
├── setup.sh                    # Universal entry point
│
├── Windows (PowerShell)
│   ├── Setup-All.ps1           # Master script
│   ├── Install-OpenClaw.ps1    # WSL + Node.js + OpenClaw
│   ├── Install-Chrome-WSL.ps1  # Chrome in WSL
│   ├── Create-OpenClawShortcuts.ps1
│   ├── Start-OpenClawGateway.ps1
│   └── Reset-OpenClaw.ps1
│
├── macOS / Linux (Bash)
│   ├── setup-all.sh            # Master script
│   ├── install-openclaw.sh     # Node.js + OpenClaw
│   ├── install-chrome.sh       # Chrome
│   ├── start-gateway.sh
│   └── reset-openclaw.sh
```

## After Installation

```bash
# Start gateway
openclaw gateway start

# Check status
openclaw gateway status

# Open terminal UI
openclaw tui

# Restart gateway
openclaw gateway restart
```

## Reset / Uninstall

```bash
openclaw gateway stop
rm -rf ~/.openclaw
sudo npm uninstall -g openclaw
```

## License

MIT
