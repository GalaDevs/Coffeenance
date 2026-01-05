#!/bin/bash

# Supabase Email Template Upload Helper
# Note: Supabase doesn't have CLI commands for email templates
# This script will help you complete the process quickly

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "        📧 SUPABASE EMAIL TEMPLATE UPLOAD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Copy template to clipboard
echo "📋 Copying email template to clipboard..."
cat email_templates/verification_template_modern.html | pbcopy

if [ $? -eq 0 ]; then
    echo "✅ Template copied to clipboard!"
else
    echo "❌ Failed to copy to clipboard"
    exit 1
fi

echo ""
echo "🌐 Opening Supabase Dashboard in browser..."
open "https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/templates"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 NEXT STEPS (IN THE BROWSER):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Find 'Confirm signup' template"
echo "2. Click the '...' menu → 'Edit message'"
echo "3. Delete existing HTML content"
echo "4. Press Cmd+V (template is in clipboard)"
echo "5. Click 'Save'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Template Variables:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   {{ .ConfirmationURL }} - Verification link"
echo "   {{ .Email }}           - User's email"
echo "   {{ .ShopName }}        - Shop name"
echo "   {{ .StaffName }}       - Staff name"
echo ""
echo "All required variables are included in the template! ✅"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  BEFORE TESTING:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Make sure these images are uploaded to server:"
echo "   • https://galadevs.com/images/galadevs-logo-navy.png"
echo "   • https://galadevs.com/images/cafenance-icon.png"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
