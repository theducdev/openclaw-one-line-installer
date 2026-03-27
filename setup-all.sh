#!/bin/bash
# setup-all.sh
# Master script - full OpenClaw setup for macOS / Ubuntu / Linux
# Usage: bash setup-all.sh [--skip-chrome] [--skip-onboard]

set -e

SKIP_CHROME=false
SKIP_ONBOARD=false

for arg in "$@"; do
    case "$arg" in
        --skip-chrome) SKIP_CHROME=true ;;
        --skip-onboard) SKIP_ONBOARD=true ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << 'EOF'
=============================================
   OpenClaw Quick Setup - Techla Project
=============================================
EOF
echo -e "${NC}"

# Step 1: Install OpenClaw
echo -e "${CYAN}[Step 1/3] Installing OpenClaw...${NC}"
bash "$SCRIPT_DIR/install-openclaw.sh"

# Step 2: Install Chrome (optional)
if [[ "$SKIP_CHROME" == false ]]; then
    echo -e "\n${CYAN}[Step 2/3] Installing Chrome...${NC}"
    bash "$SCRIPT_DIR/install-chrome.sh"
else
    echo -e "\n${CYAN}[Step 2/3] Skipping Chrome install.${NC}"
fi

# Step 3: Run onboarding
if [[ "$SKIP_ONBOARD" == false ]]; then
    echo -e "\n${CYAN}[Step 3/3] Starting OpenClaw onboarding...${NC}"
    echo -e "${YELLOW}Follow the interactive wizard below:${NC}\n"
    openclaw onboard --install-daemon
else
    echo -e "\n${CYAN}[Step 3/3] Skipping onboarding.${NC}"
fi

echo -e "${GREEN}"
cat << 'EOF'

=============================================
        Setup Complete!
=============================================

What was installed:
  - Node.js 22
  - OpenClaw (latest)
  - Google Chrome (for web scraping)

Useful commands:
  openclaw gateway start    - Start gateway
  openclaw gateway status   - Check status
  openclaw gateway restart  - Restart gateway
  openclaw tui              - Terminal UI

Helper scripts:
  bash start-gateway.sh     - Start/check gateway
  bash reset-openclaw.sh    - Factory reset (deletes all data)

=============================================
EOF
echo -e "${NC}"
