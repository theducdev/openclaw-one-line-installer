#!/bin/bash
# reset-openclaw.sh
# WARNING: This deletes all OpenClaw data!
# Usage: bash reset-openclaw.sh

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}WARNING: This will DELETE all OpenClaw data!${NC}"
read -p "Type 'yes' to confirm: " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo -e "${YELLOW}Aborted.${NC}"
    exit 0
fi

echo -e "${YELLOW}Stopping gateway...${NC}"
openclaw gateway stop 2>/dev/null || true

echo -e "${YELLOW}Removing OpenClaw data...${NC}"
rm -rf ~/.openclaw

echo -e "${GREEN}OpenClaw has been reset. Run 'openclaw onboard --install-daemon' to set up again.${NC}"
