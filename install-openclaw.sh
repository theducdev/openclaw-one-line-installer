#!/bin/bash
# install-openclaw.sh
# Works on: macOS, Ubuntu/Debian, Linux
# Usage: bash install-openclaw.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=== OpenClaw Automated Installer ===${NC}"

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
        OS="debian"
    elif [[ "$ID" == "fedora" || "$ID" == "centos" || "$ID" == "rhel" || "$ID_LIKE" == *"rhel"* ]]; then
        OS="rhel"
    elif [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
        OS="arch"
    fi
fi

echo -e "${CYAN}Detected OS: ${OS}${NC}"

# Install Node.js 22
install_node() {
    if command -v node &>/dev/null; then
        NODE_VERSION=$(node --version)
        echo -e "${GREEN}Node.js already installed: ${NODE_VERSION}${NC}"
        # Check if version is 22+
        MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
        if [[ "$MAJOR" -ge 22 ]]; then
            return 0
        fi
        echo -e "${YELLOW}Node.js version too old, upgrading...${NC}"
    fi

    echo -e "${YELLOW}Installing Node.js 22...${NC}"
    case "$OS" in
        macos)
            if command -v brew &>/dev/null; then
                brew install node@22
                brew link --overwrite node@22
            else
                echo -e "${YELLOW}Installing Homebrew first...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                brew install node@22
                brew link --overwrite node@22
            fi
            ;;
        debian)
            curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
            sudo apt-get install -y nodejs
            ;;
        rhel)
            curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
            sudo yum install -y nodejs
            ;;
        arch)
            sudo pacman -Sy --noconfirm nodejs npm
            ;;
        *)
            echo -e "${RED}Unsupported OS. Please install Node.js 22+ manually.${NC}"
            echo "Visit: https://nodejs.org/en/download/"
            exit 1
            ;;
    esac
}

# Install build dependencies
install_deps() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    case "$OS" in
        macos)
            # Xcode CLI tools
            if ! xcode-select -p &>/dev/null; then
                xcode-select --install 2>/dev/null || true
                echo -e "${YELLOW}Please complete Xcode CLI tools install, then re-run this script.${NC}"
                exit 1
            fi
            ;;
        debian)
            sudo apt-get update
            sudo apt-get install -y curl wget git build-essential
            ;;
        rhel)
            sudo yum install -y curl wget git gcc-c++ make
            ;;
        arch)
            sudo pacman -Sy --noconfirm curl wget git base-devel
            ;;
    esac
}

# Install OpenClaw
install_openclaw() {
    echo -e "${YELLOW}Installing OpenClaw...${NC}"
    sudo npm install -g openclaw

    VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}OpenClaw installed: ${VERSION}${NC}"
}

# Run steps
install_deps
install_node
install_openclaw

echo -e "${CYAN}"
cat << 'EOF'
=== Installation Complete ===

Next steps:
  1. Run onboarding:  openclaw onboard --install-daemon
  2. Follow the interactive setup wizard
  3. Start the gateway: openclaw gateway start

Useful commands:
  openclaw gateway status   - Check gateway status
  openclaw gateway restart  - Restart gateway
  openclaw tui              - Open terminal UI
EOF
echo -e "${NC}"
