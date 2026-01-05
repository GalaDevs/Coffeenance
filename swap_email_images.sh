#!/bin/bash

# Swap images in email template

TEMPLATE="email_templates/verification_template_embedded.html"
BACKUP="email_templates/verification_template_embedded.bak"

# Create backup
cp "$TEMPLATE" "$BACKUP"

# Extract the base64 strings
GALADEVS_BASE64=$(grep -o 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADwAAAA8[^"]*' "$TEMPLATE" | head -1)
COFFEENANCE_BASE64=$(grep -o 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAy[^"]*' "$TEMPLATE" | head -1)

echo "🔄 Swapping images..."
echo "- Hero will now have: Coffeenance logo"
echo "- Footer will now have: GalaDevs logo"

# Create temp file with swaps
sed "s|${GALADEVS_BASE64}|TEMP_PLACEHOLDER|g" "$TEMPLATE" > "$TEMPLATE.tmp"
sed "s|${COFFEENANCE_BASE64}|${GALADEVS_BASE64}|g" "$TEMPLATE.tmp" > "$TEMPLATE.tmp2"
sed "s|TEMP_PLACEHOLDER|${COFFEENANCE_BASE64}|g" "$TEMPLATE.tmp2" > "$TEMPLATE"

# Also swap the alt text
sed -i '' 's/alt="GalaDevs Logo"/alt="TEMP_ALT"/g' "$TEMPLATE"
sed -i '' 's/alt="Coffeenance Icon"/alt="GalaDevs Logo"/g' "$TEMPLATE"
sed -i '' 's/alt="TEMP_ALT"/alt="Coffeenance Icon"/g' "$TEMPLATE"

# Clean up
rm -f "$TEMPLATE.tmp" "$TEMPLATE.tmp2"

echo "✅ Images swapped successfully!"
echo "Backup saved to: $BACKUP"
