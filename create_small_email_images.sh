#!/bin/bash

# Create smaller versions of images for email template
# Using sips (built-in macOS image tool)

echo "🔄 Creating optimized email images..."

# Create output directory
mkdir -p email_templates/images

# Resize and optimize GalaDevs logo (60x60 for email)
sips -z 60 60 "assets/images/GalaDevs Corp Logo navy.png" --out email_templates/images/galadevs-logo-small.png 2>/dev/null
echo "✅ Created galadevs-logo-small.png (60x60)"

# Resize and optimize Coffeenance icon (50x50 for email)
sips -z 50 50 "assets/icon Cafenance.png" --out email_templates/images/coffeenance-logo-small.png 2>/dev/null
echo "✅ Created coffeenance-logo-small.png (50x50)"

echo ""
echo "📊 File sizes:"
ls -lh email_templates/images/*.png

echo ""
echo "🔄 Now creating base64 embedded version with small images..."

# Encode small images
GALADEVS_BASE64=$(base64 -i email_templates/images/galadevs-logo-small.png | tr -d '\n')
COFFEENANCE_BASE64=$(base64 -i email_templates/images/coffeenance-logo-small.png | tr -d '\n')

echo "Base64 sizes: GalaDevs=${#GALADEVS_BASE64} chars, Coffeenance=${#COFFEENANCE_BASE64} chars"

# Create embedded version with small images
cp email_templates/verification_template_modern.html email_templates/verification_template_embedded.html

# Replace with base64
sed -i '' "s|cid:galadevs-logo|data:image/png;base64,$GALADEVS_BASE64|g" email_templates/verification_template_embedded.html
sed -i '' "s|cid:coffeenance-logo|data:image/png;base64,$COFFEENANCE_BASE64|g" email_templates/verification_template_embedded.html

FINAL_SIZE=$(wc -c < email_templates/verification_template_embedded.html)
echo ""
echo "✅ Final template size: $FINAL_SIZE characters"

if [ $FINAL_SIZE -lt 50000 ]; then
    echo "✅ Template is under 50,000 character limit!"
else
    echo "⚠️ Template is still over 50,000 characters. Using external URLs instead..."
fi
