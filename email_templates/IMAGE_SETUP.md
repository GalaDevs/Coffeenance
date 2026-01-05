# Email Template - Image Setup Guide

## Required Images

To display logos and images in your email template, you need to upload these images to your web server:

### 1. Header Logo
- **Filename**: `coffeenance-logo.png`
- **Size**: 80x80 pixels (recommended)
- **Format**: PNG with transparent background
- **URL**: `https://galadevs.com/images/coffeenance-logo.png`

### 2. Footer Icon
- **Filename**: `coffeenance-icon.png`
- **Size**: 40x40 pixels (recommended)
- **Format**: PNG with transparent background
- **URL**: `https://galadevs.com/images/coffeenance-icon.png`

## Upload Instructions

### Option 1: Upload to galadevs.com
1. Access your hosting control panel (cPanel, FTP, etc.)
2. Navigate to: `/public_html/images/` (or `/htdocs/images/`)
3. Upload the logo files:
   - `coffeenance-logo.png` (80x80px)
   - `coffeenance-icon.png` (40x40px)
4. Verify URLs are accessible:
   - https://galadevs.com/images/coffeenance-logo.png
   - https://galadevs.com/images/coffeenance-icon.png

### Option 2: Use Existing Assets
If you already have images in `assets/images/`:
1. Copy them to your web server
2. Update the email template URLs to match your hosted location

### Option 3: Use a CDN
Upload images to:
- AWS S3
- Cloudinary
- ImgBB
- GitHub Pages

Then update the image URLs in the template.

## Fallback Behavior

The template includes fallback handling:
- If logo image fails to load → Shows coffee emoji ☕
- If footer icon fails to load → Icon hidden, text remains

## Email Client Compatibility

✅ **Supported features:**
- PNG images with transparency
- Absolute URLs (https://)
- Inline styles
- Alt text for accessibility

❌ **Avoid:**
- Relative URLs (`/images/logo.png`)
- File URLs (`file:///...`)
- Data URIs (some email clients block them)
- SVG files (not supported in many email clients)

## Testing

After uploading images, test the template in:
1. Gmail (Web & App)
2. Outlook (Web & Desktop)
3. Apple Mail
4. Mobile devices (iOS/Android)

## Update Template URLs

If using different URLs, update these lines in `verification_template_modern.html`:

```html
<!-- Header Logo -->
<img src="YOUR_LOGO_URL_HERE" 
     alt="Coffeenance Logo" 
     class="logo-image">

<!-- Footer Icon -->
<img src="YOUR_ICON_URL_HERE" 
     alt="Coffeenance" 
     class="footer-logo">
```
