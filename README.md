# openclaw-one-line-installer

One command to install OpenClaw on any customer laptop. Supports **macOS**, **Ubuntu/Debian**, **Fedora/RHEL**, **Arch Linux**, and **Windows**.

## Quick Start

### macOS / Linux / Ubuntu

```bash
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash
```

### Windows (PowerShell as Admin)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force; iwr -useb https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.ps1 | iex
```

## Options

```bash
# Skip Chrome install
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash -s -- --skip-chrome

# Skip GPT Codex OAuth login
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash -s -- --skip-codex

# Pre-configure API key
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash -s -- --api-key=sk-xxxxx

# Skip interactive onboarding
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash -s -- --skip-onboard

# Combine options
curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash -s -- --skip-chrome --api-key=sk-xxxxx
```

Windows options (set env vars before running):

```powershell
$env:SKIP_CODEX="true"; iwr -useb https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.ps1 | iex
```

## What Gets Installed

| Component | Purpose |
|-----------|---------|
| Node.js 22 | Runtime for OpenClaw |
| OpenClaw | AI assistant platform |
| Google Chrome | Web scraping support |
| GPT Codex OAuth | Login to OpenAI, use Codex models (codex-mini, gpt-5.4, etc.) |

## GPT Codex Auth Flow

The installer includes **automatic OpenAI OAuth login** (same flow as Codex CLI):

1. Generates PKCE code_verifier + code_challenge (S256)
2. Opens browser to OpenAI login page
3. Listens on `localhost:1455` for OAuth callback
4. Exchanges auth code for access_token + refresh_token
5. Saves tokens to `~/.openclaw/agents/main/agent/auth-profiles.json`
6. Sets default model to `openai-codex/codex-mini-latest`

After auth, these GPT Codex models are available:

| Model | Description |
|-------|-------------|
| codex-mini-latest | Fast, lightweight |
| gpt-5.4 | Most capable |
| gpt-5.3-codex | Balanced |
| gpt-5.3-codex-high | High quality |
| gpt-5.2-codex | Previous gen |

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
