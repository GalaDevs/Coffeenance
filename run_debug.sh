#!/bin/bash

# Automatic Live Debugging - Shows Flutter output in real-time with colors
# Usage: ./run_debug.sh

set -e

PROJECT_DIR="/Applications/XAMPP/xamppfiles/htdocs/Coffeenance"
LOG_FILE="$PROJECT_DIR/flutter_debug_live.log"
DEVICE="iPhone 17"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping app...${NC}"
    pkill -P $$ 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}    🔍 LIVE DEBUG MODE - AUTOMATIC OUTPUT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✓${NC} Device: ${CYAN}$DEVICE${NC}"
echo -e "${GREEN}✓${NC} Debug output will appear below with colors"
echo -e "${GREEN}✓${NC} Log file: ${CYAN}flutter_debug_live.log${NC}"
echo -e "${YELLOW}ℹ${NC}  Press ${RED}Ctrl+C${NC} to stop app and debugging"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Kill any existing Flutter processes
pkill -9 -f "flutter run" 2>/dev/null || true
sleep 1

# Clear old log
> "$LOG_FILE"

# Start Flutter and colorize output in real-time
cd "$PROJECT_DIR"
flutter run -d "$DEVICE" 2>&1 | while IFS= read -r line; do
    # Save to log file
    echo "$line" >> "$LOG_FILE"
    
    # Color code based on content
    if [[ $line == *"Error"* ]] || [[ $line == *"error"* ]] || [[ $line == *"❌"* ]] || [[ $line == *"Exception"* ]] || [[ $line == *"Failed"* ]]; then
        echo -e "${RED}$line${NC}"
    elif [[ $line == *"Warning"* ]] || [[ $line == *"warning"* ]] || [[ $line == *"⚠️"* ]]; then
        echo -e "${YELLOW}$line${NC}"
    elif [[ $line == *"✅"* ]] || [[ $line == *"Success"* ]] || [[ $line == *"success"* ]] || [[ $line == *"completed"* ]]; then
        echo -e "${GREEN}$line${NC}"
    elif [[ $line == *"flutter:"* ]]; then
        # Flutter debug prints - most important!
        if [[ $line == *"❌"* ]] || [[ $line == *"Error"* ]]; then
            echo -e "${BOLD}${RED}$line${NC}"
        elif [[ $line == *"⚠️"* ]]; then
            echo -e "${BOLD}${YELLOW}$line${NC}"
        elif [[ $line == *"✅"* ]]; then
            echo -e "${BOLD}${GREEN}$line${NC}"
        else
            echo -e "${BOLD}${CYAN}$line${NC}"
        fi
    elif [[ $line == *"🔐"* ]] || [[ $line == *"🆕"* ]] || [[ $line == *"👤"* ]] || [[ $line == *"📧"* ]]; then
        echo -e "${MAGENTA}$line${NC}"
    elif [[ $line == *"email"* ]] || [[ $line == *"verification"* ]] || [[ $line == *"verify"* ]]; then
        echo -e "${CYAN}$line${NC}"
    elif [[ $line == *"coffeenance://"* ]] || [[ $line == *"deep link"* ]]; then
        echo -e "${BOLD}${BLUE}$line${NC}"
    elif [[ $line == *"Launching"* ]] || [[ $line == *"Running"* ]] || [[ $line == *"Syncing"* ]] || [[ $line == *"Building"* ]]; then
        echo -e "${BLUE}$line${NC}"
    else
        echo "$line"
    fi
done
