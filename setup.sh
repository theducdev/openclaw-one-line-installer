#!/bin/bash
# setup.sh - Universal entry point
# Auto-detects OS and runs the right setup
#
# Usage (copy-paste to customer terminal):
#   curl -sL <your-url>/setup.sh | bash
#   -- or --
#   bash setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Detecting operating system..."

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    echo "Windows detected. Please run Setup-All.ps1 in PowerShell as Administrator:"
    echo ""
    echo "  powershell -ExecutionPolicy RemoteSigned -File Setup-All.ps1"
    echo ""
    exit 0
fi

# macOS or Linux
bash "$SCRIPT_DIR/setup-all.sh" "$@"
