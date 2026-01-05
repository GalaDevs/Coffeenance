#!/bin/bash

# Email Verification Testing Script
# This script helps you test email verification features via CLI

echo "🧪 Email Verification Testing - Coffeenance"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Main menu
echo "Select a test option:"
echo ""
echo "1. 🚀 Run app on iOS Simulator"
echo "2. 🔗 Test deep link on iOS Simulator"
echo "3. 📧 Verify Supabase email configuration"
echo "4. 🔍 Check deep link configuration"
echo "5. 📱 List available devices"
echo "6. 🧹 Clean and rebuild"
echo "7. 📦 Build release APK"
echo "8. 🏗️  Build iOS release"
echo "9. 🌐 Run on Chrome (web)"
echo "0. ❌ Exit"
echo ""
read -p "Enter option (0-9): " option

case $option in
    1)
        echo ""
        print_info "Starting app on iOS Simulator..."
        echo ""
        
        # Boot simulator if not running
        xcrun simctl boot "iPhone 17" 2>/dev/null
        
        # Wait a moment for boot
        sleep 2
        
        # Run Flutter app
        flutter run -d "iPhone 17"
        ;;
        
    2)
        echo ""
        print_info "Testing deep link on iOS Simulator..."
        echo ""
        
        # First, check if simulator is booted
        BOOTED=$(xcrun simctl list devices | grep "Booted")
        
        if [ -z "$BOOTED" ]; then
            print_warning "No simulator is running. Booting iPhone 17..."
            xcrun simctl boot "iPhone 17"
            sleep 3
        fi
        
        # Open simulator
        open -a Simulator
        
        # Test deep link
        print_info "Opening deep link: coffeenance://verify-email"
        xcrun simctl openurl booted "coffeenance://verify-email?test=true"
        
        print_success "Deep link sent! Check the simulator."
        ;;
        
    3)
        echo ""
        print_info "Supabase Email Configuration Checklist"
        echo ""
        echo "Please verify these settings in Supabase Dashboard:"
        echo ""
        echo "📋 Step 1: Enable Email Confirmation"
        echo "   URL: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/providers"
        echo "   Action: Check ☑ 'Confirm email' under Email provider"
        echo ""
        echo "📋 Step 2: Configure Redirect URLs"
        echo "   URL: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/url-configuration"
        echo "   Add these URLs:"
        echo "   - coffeenance://verify-email"
        echo "   - coffeenance://**"
        echo "   - https://tpejvjznleoinsanrgut.supabase.co/**"
        echo ""
        echo "📋 Step 3: Set Site URL"
        echo "   Set to: coffeenance://verify-email"
        echo ""
        echo "📋 Step 4 (Optional): Custom SMTP"
        echo "   URL: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/settings/auth"
        echo "   Recommended: SendGrid (100k free emails/month)"
        echo ""
        read -p "Press Enter to open Supabase Dashboard..."
        open "https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/providers"
        ;;
        
    4)
        echo ""
        print_info "Checking deep link configuration..."
        echo ""
        
        # Check Android manifest
        print_info "Android Configuration:"
        if grep -q "coffeenance" android/app/src/main/AndroidManifest.xml; then
            print_success "Deep link configured in AndroidManifest.xml"
            grep -A 5 "coffeenance" android/app/src/main/AndroidManifest.xml | head -10
        else
            print_error "Deep link NOT found in AndroidManifest.xml"
        fi
        
        echo ""
        
        # Check iOS plist
        print_info "iOS Configuration:"
        if grep -q "coffeenance" ios/Runner/Info.plist; then
            print_success "Deep link configured in Info.plist"
            grep -A 5 "coffeenance" ios/Runner/Info.plist | head -10
        else
            print_error "Deep link NOT found in Info.plist"
        fi
        
        echo ""
        
        # Check if app_links package is installed
        print_info "Checking app_links package..."
        if grep -q "app_links" pubspec.yaml; then
            print_success "app_links package found in pubspec.yaml"
        else
            print_error "app_links package NOT found in pubspec.yaml"
        fi
        ;;
        
    5)
        echo ""
        print_info "Available devices:"
        echo ""
        flutter devices
        echo ""
        print_info "iOS Simulators:"
        xcrun simctl list devices available | grep iPhone
        ;;
        
    6)
        echo ""
        print_info "Cleaning and rebuilding..."
        echo ""
        flutter clean
        flutter pub get
        print_success "Clean complete! Ready to run."
        ;;
        
    7)
        echo ""
        print_info "Building release APK for Android..."
        echo ""
        flutter build apk --release
        
        if [ $? -eq 0 ]; then
            print_success "APK built successfully!"
            echo ""
            echo "Location: build/app/outputs/flutter-apk/app-release.apk"
            echo ""
            read -p "Open build folder? (y/n): " open_folder
            if [ "$open_folder" = "y" ]; then
                open build/app/outputs/flutter-apk/
            fi
        else
            print_error "Build failed!"
        fi
        ;;
        
    8)
        echo ""
        print_info "Building iOS release..."
        echo ""
        flutter build ios --release
        
        if [ $? -eq 0 ]; then
            print_success "iOS build complete!"
        else
            print_error "Build failed!"
        fi
        ;;
        
    9)
        echo ""
        print_info "Running on Chrome..."
        echo ""
        flutter run -d chrome --web-port=8080
        ;;
        
    0)
        echo ""
        print_info "Exiting..."
        exit 0
        ;;
        
    *)
        print_error "Invalid option!"
        ;;
esac

echo ""
print_info "Test complete!"
echo ""
