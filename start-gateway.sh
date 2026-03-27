#!/bin/bash
# start-gateway.sh
# Start or check OpenClaw gateway
# Usage: bash start-gateway.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

STATUS=$(openclaw gateway status 2>&1 || true)

if echo "$STATUS" | grep -qi "running"; then
    echo -e "${GREEN}OpenClaw gateway is already running.${NC}"
    openclaw gateway status
else
    echo -e "${YELLOW}Starting OpenClaw gateway...${NC}"
    openclaw gateway start
    sleep 3
    openclaw gateway status
fi
