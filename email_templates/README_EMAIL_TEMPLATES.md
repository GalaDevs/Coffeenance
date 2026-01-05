# Email Verification Templates

## Overview
This folder contains 2 professional email verification templates for Coffeenance.

## Templates

### 1. Modern Template (`verification_template_modern.html`)
**Style:** Colorful gradient with brown coffee theme
**Features:**
- Gradient brown header with coffee icon
- Warm, welcoming design
- Yellow expiry notice box
- Mobile responsive
- Clear call-to-action button

**Best for:** Friendly, approachable brand feel

---

### 2. Minimalist Template (`verification_template_minimalist.html`)
**Style:** Clean, minimal black and white
**Features:**
- Minimalist design with subtle borders
- Professional typography
- Blue info box
- Rounded pill button
- Ultra-clean layout

**Best for:** Professional, modern brand feel

---

## How to Use in Supabase

### Step 1: Choose Your Template
Pick either `verification_template_modern.html` or `verification_template_minimalist.html`

### Step 2: Upload to Supabase
1. Go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut
2. Navigate to: **Authentication** → **Email Templates**
3. Find: **Confirm signup** template
4. Copy the entire content of your chosen template
5. Paste it into the **Email Template** editor
6. Click **Save**

### Step 3: Test
1. Create a new test user account
2. Check the email inbox
3. Verify the template displays correctly

---

## Template Variables

Both templates use these Supabase variables:
- `{{ .ConfirmationURL }}` - The verification link
- `{{ .Email }}` - User's email address (used in minimalist template)

These are automatically replaced by Supabase when sending emails.

---

## Customization

### Change Colors

**Modern Template:**
- Header gradient: `.header { background: linear-gradient(135deg, #6B4423 0%, #8B5A3C 100%); }`
- Button: `.verify-button { background: linear-gradient(...) }`

**Minimalist Template:**
- Button color: `.verify-btn { background-color: #2c2c2c; }`
- Info box: `.info-box { background-color: #f0f8ff; border-left: 3px solid #4a90e2; }`

### Change Text
Simply edit the HTML text content within the `<p>` and `<h1>` tags.

---

## Testing Locally

To preview these templates:
1. Open the HTML file in your browser
2. Replace `{{ .ConfirmationURL }}` with a test URL like `https://example.com/verify`
3. Replace `{{ .Email }}` with a test email

---

## Mobile Responsive
Both templates are fully mobile-responsive with breakpoints at 600px width.

---

## Support
If you need help customizing these templates, refer to:
- Supabase Email Templates Documentation
- HTML Email Best Practices
