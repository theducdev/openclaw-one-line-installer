#!/bin/bash
# =============================================================
#   OpenClaw One-Line Installer - Techla Project
# =============================================================
#
# Usage (customer runs this single command):
#
#   curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB/openclaw-setup/main/install.sh | bash
#
# Or with options:
#   curl -fsSL https://URL/install.sh | bash -s -- --skip-chrome
#   curl -fsSL https://URL/install.sh | bash -s -- --api-key YOUR_KEY
#
# Supports: macOS, Ubuntu, Debian, Fedora, CentOS, RHEL, Arch
# =============================================================

set -e

# --------------- Config ---------------
NODE_VERSION="22"
SKIP_CHROME=false
SKIP_ONBOARD=false
API_KEY=""

for arg in "$@"; do
    case "$arg" in
        --skip-chrome)  SKIP_CHROME=true ;;
        --skip-onboard) SKIP_ONBOARD=true ;;
        --api-key=*)    API_KEY="${arg#*=}" ;;
    esac
done

# --------------- Colors ---------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# --------------- Helpers ---------------
info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()    { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --------------- Banner ---------------
echo -e "${BOLD}${CYAN}"
cat << 'BANNER'

   ___                    ____ _
  / _ \ _ __   ___ _ __  / ___| | __ ___      __
 | | | | '_ \ / _ \ '_ \| |   | |/ _` \ \ /\ / /
 | |_| | |_) |  __/ | | | |___| | (_| |\ V  V /
  \___/| .__/ \___|_| |_|\____|_|\__,_| \_/\_/
       |_|

  One-Line Installer — Techla Project

BANNER
echo -e "${NC}"

# --------------- Detect OS ---------------
detect_os() {
    OS="unknown"
    DISTRO="unknown"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        OS="windows"
        DISTRO="windows"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="linux"
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
            DISTRO="debian"
        elif [[ "$ID" == "fedora" || "$ID" == "centos" || "$ID" == "rhel" || "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* ]]; then
            DISTRO="rhel"
        elif [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
            DISTRO="arch"
        fi
    fi

    info "Detected: OS=$OS, Distro=$DISTRO"
}

# --------------- Check root/sudo ---------------
check_sudo() {
    if [[ "$EUID" -eq 0 ]]; then
        SUDO=""
    elif command -v sudo &>/dev/null; then
        SUDO="sudo"
    else
        fail "This script needs sudo. Please install sudo or run as root."
    fi
}

# --------------- Install dependencies ---------------
install_deps() {
    info "Installing system dependencies..."

    case "$DISTRO" in
        macos)
            if ! xcode-select -p &>/dev/null; then
                info "Installing Xcode CLI tools..."
                xcode-select --install 2>/dev/null || true
                echo ""
                warn "Please complete Xcode CLI tools install popup, then re-run:"
                echo "  curl -fsSL <url>/install.sh | bash"
                exit 1
            fi
            if ! command -v brew &>/dev/null; then
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                # Add brew to PATH for Apple Silicon
                if [[ -f /opt/homebrew/bin/brew ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            fi
            ;;
        debian)
            $SUDO apt-get update -qq
            $SUDO apt-get install -y -qq curl wget git build-essential
            ;;
        rhel)
            $SUDO yum install -y curl wget git gcc-c++ make
            ;;
        arch)
            $SUDO pacman -Sy --noconfirm curl wget git base-devel
            ;;
        *)
            fail "Unsupported distro: $DISTRO. Please install Node.js 22+ and OpenClaw manually."
            ;;
    esac

    success "Dependencies installed."
}

# --------------- Install Node.js ---------------
install_node() {
    # Check existing Node.js
    if command -v node &>/dev/null; then
        CURRENT=$(node --version | sed 's/v//' | cut -d. -f1)
        if [[ "$CURRENT" -ge "$NODE_VERSION" ]]; then
            success "Node.js already installed: $(node --version)"
            return 0
        fi
        warn "Node.js $(node --version) is too old, upgrading to v${NODE_VERSION}..."
    fi

    info "Installing Node.js ${NODE_VERSION}..."

    case "$DISTRO" in
        macos)
            brew install node@${NODE_VERSION}
            brew link --overwrite node@${NODE_VERSION} 2>/dev/null || true
            ;;
        debian)
            curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | $SUDO bash -
            $SUDO apt-get install -y -qq nodejs
            ;;
        rhel)
            curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | $SUDO bash -
            $SUDO yum install -y nodejs
            ;;
        arch)
            $SUDO pacman -Sy --noconfirm nodejs npm
            ;;
    esac

    success "Node.js installed: $(node --version)"
}

# --------------- Install Chrome ---------------
install_chrome() {
    if [[ "$SKIP_CHROME" == true ]]; then
        info "Skipping Chrome install (--skip-chrome)."
        return 0
    fi

    # Check if already installed
    if command -v google-chrome &>/dev/null || command -v google-chrome-stable &>/dev/null; then
        success "Chrome already installed."
        return 0
    fi
    if [[ "$DISTRO" == "macos" && -d "/Applications/Google Chrome.app" ]]; then
        success "Chrome already installed."
        return 0
    fi

    info "Installing Google Chrome..."

    case "$DISTRO" in
        macos)
            brew install --cask google-chrome
            ;;
        debian)
            cd /tmp
            wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            $SUDO dpkg -i google-chrome-stable_current_amd64.deb || $SUDO apt-get install -f -y
            rm -f google-chrome-stable_current_amd64.deb
            ;;
        rhel)
            $SUDO dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
            ;;
        arch)
            $SUDO pacman -Sy --noconfirm chromium
            ;;
    esac

    success "Chrome installed."
}

# --------------- Install OpenClaw ---------------
install_openclaw() {
    info "Installing OpenClaw..."

    $SUDO npm install -g openclaw

    if command -v openclaw &>/dev/null; then
        success "OpenClaw installed: $(openclaw --version)"
    else
        fail "OpenClaw installation failed."
    fi
}

# --------------- Configure API key ---------------
configure_api_key() {
    if [[ -n "$API_KEY" ]]; then
        info "Configuring API key..."
        mkdir -p ~/.openclaw
        # Write config with API key
        cat > ~/.openclaw/config.json << EOF
{
  "apiKey": "$API_KEY"
}
EOF
        success "API key configured."
    fi
}

# --------------- Run onboarding ---------------
run_onboard() {
    if [[ "$SKIP_ONBOARD" == true ]]; then
        info "Skipping onboarding (--skip-onboard)."
        return 0
    fi

    echo ""
    info "Starting OpenClaw onboarding wizard..."
    echo -e "${YELLOW}Follow the steps below to complete setup:${NC}"
    echo ""
    openclaw onboard --install-daemon
}

# --------------- Done ---------------
print_done() {
    echo -e "${BOLD}${GREEN}"
    cat << 'DONE'

=============================================
        ✅ Setup Complete!
=============================================

Useful commands:
  openclaw gateway start    — Start gateway
  openclaw gateway status   — Check status
  openclaw gateway restart  — Restart gateway
  openclaw tui              — Terminal UI

To reset everything:
  openclaw gateway stop
  rm -rf ~/.openclaw
  openclaw onboard --install-daemon

=============================================

DONE
    echo -e "${NC}"
}

# --------------- Main ---------------
main() {
    detect_os

    if [[ "$OS" == "windows" ]]; then
        fail "Windows detected. Please use PowerShell instead:\n  powershell -ExecutionPolicy RemoteSigned -File Setup-All.ps1"
    fi

    check_sudo
    install_deps
    install_node
    install_chrome
    install_openclaw
    configure_api_key
    print_done
    run_onboard
}

main "$@"
