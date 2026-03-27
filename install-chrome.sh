#!/bin/bash
# install-chrome.sh
# Install Chrome on macOS / Ubuntu / Linux
# Usage: bash install-chrome.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=== Installing Google Chrome ===${NC}"

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

case "$OS" in
    macos)
        if [[ -d "/Applications/Google Chrome.app" ]]; then
            echo -e "${GREEN}Chrome is already installed.${NC}"
        else
            echo -e "${YELLOW}Installing Chrome via Homebrew...${NC}"
            brew install --cask google-chrome
        fi
        ;;
    debian)
        echo -e "${YELLOW}Downloading Chrome...${NC}"
        cd /tmp
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        echo -e "${YELLOW}Installing Chrome...${NC}"
        sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt-get install -f -y
        rm -f google-chrome-stable_current_amd64.deb
        ;;
    rhel)
        echo -e "${YELLOW}Installing Chrome...${NC}"
        sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
        ;;
    arch)
        echo -e "${YELLOW}Installing Chromium...${NC}"
        sudo pacman -Sy --noconfirm chromium
        ;;
    *)
        echo -e "${RED}Unsupported OS. Please install Chrome manually.${NC}"
        exit 1
        ;;
esac

# Verify
if command -v google-chrome &>/dev/null; then
    echo -e "${GREEN}Chrome installed: $(google-chrome --version)${NC}"
elif command -v chromium &>/dev/null; then
    echo -e "${GREEN}Chromium installed: $(chromium --version)${NC}"
fi

echo -e "${GREEN}Chrome installation complete!${NC}"
