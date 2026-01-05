# Upload Email Template to Supabase

## Quick Steps

### 1. Open the Email Template
```bash
open email_templates/verification_template_modern.html
```

### 2. Copy the HTML Content
- Select all content (Cmd + A)
- Copy (Cmd + C)

### 3. Go to Supabase Dashboard
🔗 https://supabase.com/dashboard/project/tpejvjznleoinsanrgut

### 4. Navigate to Email Templates
1. Click **Authentication** in the left sidebar
2. Click **Email Templates**
3. Find **Confirm signup** template

### 5. Paste the Template
1. Click **Edit** on "Confirm signup"
2. **Delete** the default template content
3. **Paste** your copied HTML (Cmd + V)
4. Click **Save**

---

## Required Variables

Make sure these Supabase variables are in the template:
- `{{ .ConfirmationURL }}` - The verification link
- `{{ .Email }}` - User's email address
- `{{ .ShopName }}` - Shop name (if available)
- `{{ .StaffName }}` - Staff name (if available)

✅ All variables are already included in the template!

---

## Before Upload Checklist

☐ Images uploaded to server:
  - https://galadevs.com/images/galadevs-logo-navy.png
  - https://galadevs.com/images/cafenance-icon.png

☐ SMTP configured in Supabase (noreply@galadevs.com)

☐ Email rate limit increased (100+ emails/hour)

---

## Test After Upload

1. Create a new user account in the app
2. Check email inbox for verification email
3. Verify the design and branding appears correctly
4. Test "Verify Account" button
5. Test "Get the App" button

---

## Troubleshooting

### Images not showing?
- Verify images are uploaded to https://galadevs.com/images/
- Check image URLs are accessible (use curl)

### Email not sending?
- Check SMTP settings in Supabase
- Verify rate limits not exceeded
- Check Supabase logs

### Buttons not working?
- Verify redirect URLs are configured in Supabase Auth
- Check coffeenance:// deep link is set up

---

## Direct Link to Template Editor

https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/templates

---

**Need help?** Contact GalaDevs: info@galadevs.com
