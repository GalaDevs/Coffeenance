#!/bin/bash

# Supabase Email Template Upload Script
# This script uploads the minimalist email verification template to Supabase

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📧 Supabase Email Template Upload"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if template file exists
TEMPLATE_FILE="email_templates/verification_template_modern.html"
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Error: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

echo "✅ Found template file"
echo ""

# Read the template content
TEMPLATE_CONTENT=$(cat "$TEMPLATE_FILE")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  MANUAL STEPS REQUIRED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Unfortunately, Supabase doesn't support updating email templates via CLI."
echo "You need to manually copy the template to the Dashboard."
echo ""
echo "STEPS:"
echo "1. Open: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut"
echo "2. Go to: Authentication → Email Templates"
echo "3. Find: 'Confirm signup' template"
echo "4. Copy the template content (already copied to clipboard if available)"
echo ""
echo "Would you like to:"
echo "  [1] View the template in terminal"
echo "  [2] Open Supabase Dashboard in browser"
echo "  [3] Exit"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📄 Template Content:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$TEMPLATE_FILE"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Copy the above content and paste it into Supabase Dashboard"
        ;;
    2)
        echo ""
        echo "🌐 Opening Supabase Dashboard..."
        open "https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/templates"
        echo "✅ Browser opened. Navigate to 'Confirm signup' template and paste the content."
        ;;
    3)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Paste the template HTML into 'Confirm signup' template editor"
echo "2. Click 'Save' in Supabase Dashboard"
echo "3. Test by creating a new user account"
echo ""
echo "Template variables used:"
echo "  • {{ .ConfirmationURL }} - Email verification link"
echo "  • {{ .Email }} - User's email address"
echo ""
