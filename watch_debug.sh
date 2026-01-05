#!/bin/bash

# Live Debug Monitor for Coffeenance
# Shows real-time Flutter debugging output with color

echo "🔍 LIVE DEBUG MONITOR"
echo "===================="
echo ""
echo "Monitoring: flutter_debug_live.log"
echo "Press Ctrl+C to stop"
echo ""

# Follow the log file with colored output
tail -f flutter_debug_live.log | while read line; do
    if [[ $line == *"Error"* ]] || [[ $line == *"error"* ]] || [[ $line == *"❌"* ]]; then
        echo -e "\033[0;31m$line\033[0m"  # Red for errors
    elif [[ $line == *"Warning"* ]] || [[ $line == *"⚠️"* ]]; then
        echo -e "\033[0;33m$line\033[0m"  # Yellow for warnings
    elif [[ $line == *"✅"* ]] || [[ $line == *"Success"* ]]; then
        echo -e "\033[0;32m$line\033[0m"  # Green for success
    elif [[ $line == *"flutter:"* ]]; then
        echo -e "\033[0;36m$line\033[0m"  # Cyan for flutter messages
    else
        echo "$line"
    fi
done
