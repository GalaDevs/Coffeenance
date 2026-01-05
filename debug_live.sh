#!/bin/bash

# Live Debugging Tool for Coffeenance Email Verification
# Real-time monitoring and debugging

echo "🔍 Live Debugging - Email Verification"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ $# -eq 0 ]; then
    echo "Usage: ./debug_live.sh [command]"
    echo ""
    echo "Commands:"
    echo "  run           - Run app with live logging"
    echo "  watch         - Watch logs for errors"
    echo "  test-verify   - Test email verification flow"
    echo "  deep-link     - Monitor deep link handling"
    echo "  check-auth    - Check auth state in real-time"
    echo "  supabase      - Monitor Supabase calls"
    echo ""
    exit 0
fi

case "$1" in
    run)
        echo "🚀 Starting app with live debugging..."
        echo ""
        flutter run -d "iPhone 17" 2>&1 | while read line; do
            # Highlight errors
            if echo "$line" | grep -qi "error"; then
                echo -e "${RED}❌ $line${NC}"
            # Highlight warnings
            elif echo "$line" | grep -qi "warning"; then
                echo -e "${YELLOW}⚠️  $line${NC}"
            # Highlight success
            elif echo "$line" | grep -qi "success\|✅\|✓"; then
                echo -e "${GREEN}✅ $line${NC}"
            # Highlight email verification
            elif echo "$line" | grep -qi "email\|verify\|verification\|confirm"; then
                echo -e "${BLUE}📧 $line${NC}"
            # Highlight deep links
            elif echo "$line" | grep -qi "deep.link\|coffeenance://"; then
                echo -e "${BLUE}🔗 $line${NC}"
            # Highlight auth
            elif echo "$line" | grep -qi "auth\|login\|sign"; then
                echo -e "${BLUE}🔐 $line${NC}"
            else
                echo "$line"
            fi
        done
        ;;
    
    watch)
        echo "👀 Watching for errors and important events..."
        echo "Press Ctrl+C to stop"
        echo ""
        
        if [ -f flutter_debug_live.log ]; then
            tail -f flutter_debug_live.log | grep --line-buffered -iE "(error|exception|failed|success|email|verify|auth|deep.link)" | while read line; do
                if echo "$line" | grep -qi "error\|exception\|failed"; then
                    echo -e "${RED}$line${NC}"
                else
                    echo -e "${GREEN}$line${NC}"
                fi
            done
        else
            echo -e "${RED}No log file found. Run './debug_live.sh run' first${NC}"
        fi
        ;;
    
    test-verify)
        echo "🧪 Testing Email Verification Flow..."
        echo ""
        
        echo "Step 1: Checking if app is running..."
        if pgrep -f "flutter run" > /dev/null; then
            echo -e "${GREEN}✅ App is running${NC}"
        else
            echo -e "${YELLOW}⚠️  App not running. Start with './debug_live.sh run'${NC}"
            exit 1
        fi
        
        echo ""
        echo "Step 2: Sending test deep link..."
        xcrun simctl openurl booted "coffeenance://verify-email?test=true"
        echo -e "${GREEN}✅ Deep link sent${NC}"
        
        echo ""
        echo "Step 3: Checking logs for deep link reception..."
        sleep 2
        if grep -q "Deep link" flutter_debug_live.log 2>/dev/null; then
            echo -e "${GREEN}✅ Deep link received by app${NC}"
        else
            echo -e "${RED}❌ Deep link not detected in logs${NC}"
        fi
        
        echo ""
        echo "📊 Recent email verification logs:"
        tail -20 flutter_debug_live.log 2>/dev/null | grep -i "email\|verify\|deep" || echo "No recent logs"
        ;;
    
    deep-link)
        echo "🔗 Monitoring Deep Link Activity..."
        echo "Press Ctrl+C to stop"
        echo ""
        
        echo "Listening for deep link events..."
        tail -f flutter_debug_live.log 2>/dev/null | grep --line-buffered -i "deep\|link\|coffeenance://" | while read line; do
            echo -e "${BLUE}🔗 $(date '+%H:%M:%S') - $line${NC}"
        done
        ;;
    
    check-auth)
        echo "🔐 Checking Authentication State..."
        echo ""
        
        # Check if Flutter app is running
        if pgrep -f "flutter run" > /dev/null; then
            echo -e "${GREEN}✅ Flutter app is running${NC}"
            echo ""
            echo "Recent auth-related logs:"
            tail -50 flutter_debug_live.log 2>/dev/null | grep -iE "auth|login|user|email.confirmed" | tail -10
        else
            echo -e "${RED}❌ App is not running${NC}"
        fi
        
        echo ""
        echo "Supabase Auth State (from Supabase Dashboard):"
        echo "Check: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/users"
        ;;
    
    supabase)
        echo "☁️  Monitoring Supabase Calls..."
        echo "Press Ctrl+C to stop"
        echo ""
        
        tail -f flutter_debug_live.log 2>/dev/null | grep --line-buffered -iE "supabase|auth\.(signIn|signUp|signOut)|verifyOTP|email.confirmed" | while read line; do
            if echo "$line" | grep -qi "error\|failed"; then
                echo -e "${RED}❌ $line${NC}"
            elif echo "$line" | grep -qi "success\|confirmed"; then
                echo -e "${GREEN}✅ $line${NC}"
            else
                echo -e "${BLUE}☁️  $line${NC}"
            fi
        done
        ;;
    
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Run without arguments to see available commands"
        ;;
esac
