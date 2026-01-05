# Email Template Setup for Supabase

## Step 1: Upload Logos to Supabase Storage

1. Go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/storage
2. Create a bucket called `assets` (make it **PUBLIC**)
3. Upload these images:
   - `coffeenance-logo.png` (from your Cafenance.png)
   - `galadevs-logo.png` (from your GalaDevs Corp Logo navy.png)

4. Get the public URLs (they'll look like):
   - `https://tpejvjznleoinsanrgut.supabase.co/storage/v1/object/public/assets/coffeenance-logo.png`
   - `https://tpejvjznleoinsanrgut.supabase.co/storage/v1/object/public/assets/galadevs-logo.png`

## Step 2: Configure Email Template in Supabase

1. Go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/templates
2. Click on **"Confirm signup"**
3. Set:
   - **Subject**: `Welcome to Coffeenance ☕ - Verify Your Email`
   - **Body**: Copy the HTML below

## Step 3: Modern Email Template (Copy This)

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;background:linear-gradient(180deg,#1a1a2e 0%,#16213e 100%);">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:linear-gradient(180deg,#1a1a2e 0%,#16213e 100%);">
    <tr>
      <td align="center" style="padding:60px 20px;">
        <table width="520" cellpadding="0" cellspacing="0" style="background:rgba(255,255,255,0.03);border-radius:24px;border:1px solid rgba(255,255,255,0.1);">
          
          <!-- Logo -->
          <tr>
            <td style="padding:50px 40px 30px;text-align:center;">
              <div style="display:inline-block;padding:8px;background:linear-gradient(135deg,#d4a574 0%,#8b5a2b 50%,#d4a574 100%);border-radius:28px;box-shadow:0 20px 60px rgba(212,165,116,0.3);">
                <img src="https://tpejvjznleoinsanrgut.supabase.co/storage/v1/object/public/assets/coffeenance-logo.png" alt="Coffeenance" width="100" height="100" style="border-radius:20px;display:block;">
              </div>
            </td>
          </tr>
          
          <!-- Title -->
          <tr>
            <td style="padding:0 40px 20px;text-align:center;">
              <h1 style="color:#ffffff;margin:0 0 8px;font-size:28px;font-weight:700;letter-spacing:-0.5px;">Welcome to Coffeenance</h1>
              <p style="color:#d4a574;margin:0;font-size:14px;font-weight:500;letter-spacing:2px;text-transform:uppercase;">Your Coffee Business Partner</p>
            </td>
          </tr>
          
          <!-- Divider -->
          <tr>
            <td style="padding:10px 60px;">
              <div style="height:1px;background:linear-gradient(90deg,transparent 0%,rgba(212,165,116,0.3) 50%,transparent 100%);"></div>
            </td>
          </tr>
          
          <!-- Message -->
          <tr>
            <td style="padding:20px 40px;">
              <p style="color:rgba(255,255,255,0.9);font-size:16px;line-height:1.7;margin:0 0 16px;text-align:center;">Thanks for signing up! You're one step away from managing your coffee shop like a pro.</p>
              <p style="color:rgba(255,255,255,0.6);font-size:14px;line-height:1.6;margin:0;text-align:center;">Verify your email to unlock sales analytics, inventory management, team collaboration, and more.</p>
            </td>
          </tr>
          
          <!-- Features -->
          <tr>
            <td style="padding:20px 30px;">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="padding:6px;text-align:center;">
                    <span style="display:inline-block;background:rgba(212,165,116,0.15);color:#d4a574;padding:8px 16px;border-radius:20px;font-size:12px;font-weight:600;">📊 Analytics</span>
                  </td>
                  <td style="padding:6px;text-align:center;">
                    <span style="display:inline-block;background:rgba(212,165,116,0.15);color:#d4a574;padding:8px 16px;border-radius:20px;font-size:12px;font-weight:600;">📦 Inventory</span>
                  </td>
                </tr>
                <tr>
                  <td style="padding:6px;text-align:center;">
                    <span style="display:inline-block;background:rgba(212,165,116,0.15);color:#d4a574;padding:8px 16px;border-radius:20px;font-size:12px;font-weight:600;">👥 Team</span>
                  </td>
                  <td style="padding:6px;text-align:center;">
                    <span style="display:inline-block;background:rgba(212,165,116,0.15);color:#d4a574;padding:8px 16px;border-radius:20px;font-size:12px;font-weight:600;">☕ Menu</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          
          <!-- Button -->
          <tr>
            <td style="padding:30px 40px;text-align:center;">
              <a href="{{ .ConfirmationURL }}" style="display:inline-block;background:linear-gradient(135deg,#d4a574 0%,#c4956a 100%);color:#1a1a2e;text-decoration:none;padding:18px 50px;border-radius:14px;font-size:16px;font-weight:700;letter-spacing:0.5px;box-shadow:0 10px 40px rgba(212,165,116,0.4);">Verify Email Address</a>
            </td>
          </tr>
          
          <!-- Alt Link -->
          <tr>
            <td style="padding:0 40px 30px;text-align:center;">
              <p style="color:rgba(255,255,255,0.4);font-size:11px;margin:0;line-height:1.6;">Or copy this link:<br><a href="{{ .ConfirmationURL }}" style="color:#d4a574;word-break:break-all;font-size:10px;">{{ .ConfirmationURL }}</a></p>
            </td>
          </tr>
          
          <!-- Footer Divider -->
          <tr>
            <td style="padding:0 40px;">
              <div style="height:1px;background:rgba(255,255,255,0.08);"></div>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="padding:30px 40px;text-align:center;">
              <p style="color:rgba(255,255,255,0.3);font-size:10px;margin:0 0 12px;letter-spacing:1px;text-transform:uppercase;">Developed by</p>
              <img src="https://tpejvjznleoinsanrgut.supabase.co/storage/v1/object/public/assets/galadevs-logo.png" alt="GalaDevs" width="44" height="44" style="border-radius:10px;opacity:0.9;">
              <p style="color:rgba(255,255,255,0.7);font-size:13px;font-weight:600;margin:12px 0 4px;">GalaDevs Technology Corporation</p>
              <p style="color:rgba(255,255,255,0.3);font-size:10px;margin:0;">© 2026 All rights reserved</p>
            </td>
          </tr>
          
        </table>
        <p style="color:rgba(255,255,255,0.2);font-size:11px;margin:30px 0 0;text-align:center;">Brew Success. Manage Smart. Grow Together.</p>
      </td>
    </tr>
  </table>
</body>
</html>
```

## Step 4: Set Redirect URL

In Supabase Authentication → URL Configuration, add:
```
coffeenance://verify-email
coffeenance://**
```

---

## 🎨 Design Features

This modern template includes:

- **Dark glassmorphism theme** - Trendy dark blue/purple gradient
- **Premium gold accents** - Elegant coffee-toned highlights (#d4a574)
- **Floating logo** with gradient border glow
- **Pill-style feature tags** - Modern chip design
- **Soft shadows** - Depth and dimension
- **Clean typography** - Apple system fonts
- **Minimal layout** - Focus on the CTA
- **GalaDevs branding** in subtle footer

The design follows 2025-2026 email trends:
✓ Dark mode friendly
✓ Glassmorphism elements
✓ Gradient accents
✓ Rounded corners
✓ Minimalist approach
