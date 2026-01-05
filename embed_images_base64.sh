#!/bin/bash

# Script to convert email template to use base64 embedded images

TEMPLATE="email_templates/verification_template_modern.html"
OUTPUT="email_templates/verification_template_embedded.html"

echo "🔄 Converting images to base64..."

# Encode the GalaDevs logo
GALADEVS_BASE64=$(base64 -i "assets/images/GalaDevs Corp Logo navy.png" | tr -d '\n')
echo "✅ Encoded GalaDevs logo (${#GALADEVS_BASE64} characters)"

# Encode the Coffeenance icon
COFFEENANCE_BASE64=$(base64 -i "assets/icon Cafenance.png" | tr -d '\n')
echo "✅ Encoded Coffeenance logo (${#COFFEENANCE_BASE64} characters)"

# Create the embedded version
cp "$TEMPLATE" "$OUTPUT"

# Replace CID references with base64 data URLs
sed -i '' "s|cid:galadevs-logo|data:image/png;base64,$GALADEVS_BASE64|g" "$OUTPUT"
sed -i '' "s|cid:coffeenance-logo|data:image/png;base64,$COFFEENANCE_BASE64|g" "$OUTPUT"

echo ""
echo "✅ Created embedded version: $OUTPUT"
echo ""
echo "📋 Next steps:"
echo "1. Copy the contents of $OUTPUT"
echo "2. Paste into Supabase Email Templates"
echo "3. Images will be embedded directly in the email"
echo ""
echo "⚠️ Note: Base64 increases email size but ensures images always display"
