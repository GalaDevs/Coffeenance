#!/bin/bash

# Quick Email Verification CLI Commands
# Run these commands to test email verification

echo "📧 Email Verification - Quick Commands"
echo "======================================"
echo ""

# Check if we have an argument
if [ $# -eq 0 ]; then
    echo "Usage: ./email_verify_cli.sh [command]"
    echo ""
    echo "Commands:"
    echo "  run        - Run app on simulator"
    echo "  test-link  - Test deep link"
    echo "  check      - Check configuration"
    echo "  supabase   - Open Supabase dashboard"
    echo "  verify     - Manually verify email in Supabase"
    echo ""
    exit 0
fi

case "$1" in
    run)
        echo "🚀 Running app..."
        flutter run -d "iPhone 17"
        ;;
    
    test-link)
        echo "🔗 Testing deep link..."
        echo "Opening: coffeenance://verify-email"
        xcrun simctl openurl booted "coffeenance://verify-email?test=true"
        echo "✅ Deep link sent!"
        ;;
    
    check)
        echo "🔍 Checking configuration..."
        echo ""
        
        # Android
        echo "📱 Android:"
        if grep -q "coffeenance://verify-email" android/app/src/main/AndroidManifest.xml; then
            echo "  ✅ Deep link configured"
        else
            echo "  ❌ Deep link NOT configured"
        fi
        
        echo ""
        
        # iOS
        echo "📱 iOS:"
        if grep -q "coffeenance" ios/Runner/Info.plist; then
            echo "  ✅ URL scheme configured"
        else
            echo "  ❌ URL scheme NOT configured"
        fi
        
        echo ""
        
        # Package
        if grep -q "app_links" pubspec.yaml; then
            echo "📦 app_links: ✅ Installed"
        else
            echo "📦 app_links: ❌ Not found"
        fi
        ;;
    
    supabase)
        echo "🌐 Opening Supabase Dashboard..."
        open "https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/providers"
        echo ""
        echo "📋 Configure these settings:"
        echo "1. Enable email confirmation"
        echo "2. Add redirect URLs:"
        echo "   - coffeenance://verify-email"
        echo "   - coffeenance://**"
        echo "3. Set Site URL: coffeenance://verify-email"
        ;;
    
    verify)
        if [ -z "$2" ]; then
            echo "❌ Please provide an email address"
            echo "Usage: ./email_verify_cli.sh verify user@example.com"
            exit 1
        fi
        
        echo "📧 Manually verifying: $2"
        echo ""
        echo "Run this SQL in Supabase SQL Editor:"
        echo ""
        echo "UPDATE auth.users"
        echo "SET email_confirmed_at = NOW()"
        echo "WHERE email = '$2';"
        echo ""
        echo "Opening SQL Editor..."
        open "https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/sql/new"
        ;;
    
    *)
        echo "❌ Unknown command: $1"
        echo "Run without arguments to see available commands"
        ;;
esac
