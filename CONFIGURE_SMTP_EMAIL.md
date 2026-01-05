# Configure Email Verification with SMTP

## Your Email Verification is Already Coded ✅
- Deep links configured: `coffeenance://verify-email`
- Email verification screen ready
- Auto-detection of verification working

**You just need to configure SMTP in Supabase!**

---

## Step-by-Step: Configure SMTP in Supabase

### Option 1: Use SendGrid (Recommended - Free 100 emails/day)

#### 1. Create SendGrid Account
1. Go to: https://signup.sendgrid.com/
2. Sign up for free account
3. Verify your email

#### 2. Get SendGrid API Key
1. Login to SendGrid dashboard
2. Go to **Settings** → **API Keys**
3. Click **Create API Key**
4. Name: "Supabase SMTP"
5. Select **"Full Access"**
6. Click **Create & View**
7. **COPY THE KEY** (you won't see it again!)

#### 3. Configure in Supabase
1. Go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut
2. Click **Authentication** → **Email Templates** (or Settings)
3. Scroll to **SMTP Settings**
4. Enable **"Enable Custom SMTP"**
5. Fill in:
   ```
   Host: smtp.sendgrid.net
   Port: 587
   Username: apikey
   Password: [YOUR_SENDGRID_API_KEY]
   Sender email: your-email@yourdomain.com
   Sender name: Coffeenance
   ```
6. Click **Save**

#### 4. Configure Redirect URLs
1. Still in **Authentication** settings
2. Find **"Redirect URLs"** section
3. Add these URLs (one per line):
   ```
   coffeenance://verify-email
   coffeenance://**
   http://localhost:3000/**
   ```
4. Set **Site URL**: `coffeenance://`
5. Click **Save**

#### 5. Test Email Verification
1. Run your app: `./run_debug.sh`
2. Register with a real email address
3. Check your email for verification link
4. Click the link - app should open!

---

### Option 2: Use Resend (Modern, Developer-Friendly)

#### 1. Create Resend Account
1. Go to: https://resend.com/signup
2. Sign up for free (100 emails/day)
3. Verify your email

#### 2. Get Resend API Key
1. Go to: https://resend.com/api-keys
2. Click **Create API Key**
3. Name: "Supabase"
4. Click **Create**
5. **COPY THE KEY**

#### 3. Configure in Supabase
1. Go to Supabase → Authentication → SMTP Settings
2. Enable Custom SMTP:
   ```
   Host: smtp.resend.com
   Port: 587
   Username: resend
   Password: [YOUR_RESEND_API_KEY]
   Sender email: onboarding@resend.dev
   Sender name: Coffeenance
   ```
3. Save and configure redirect URLs (same as above)

---

### Option 3: Gmail SMTP (For Testing Only)

⚠️ **Not recommended for production** - Use for testing only

#### Configure Gmail
1. Enable 2-Step Verification in your Google Account
2. Generate App Password:
   - Google Account → Security → 2-Step Verification
   - Scroll down to App Passwords
   - Generate password for "Mail"
3. Use in Supabase:
   ```
   Host: smtp.gmail.com
   Port: 587
   Username: your-email@gmail.com
   Password: [APP_PASSWORD]
   Sender email: your-email@gmail.com
   Sender name: Coffeenance
   ```

---

## Customize Email Template (Optional)

### Edit Verification Email
1. Supabase → Authentication → Email Templates
2. Click **"Confirm signup"** template
3. Customize the HTML email
4. Use these variables:
   - `{{ .ConfirmationURL }}` - Magic link
   - `{{ .Token }}` - Verification token
   - `{{ .SiteURL }}` - Your app URL

### Example Custom Template
```html
<h2>Welcome to Coffeenance!</h2>
<p>Click the button below to verify your email:</p>
<a href="{{ .ConfirmationURL }}" 
   style="background: #4CAF50; color: white; padding: 10px 20px; text-decoration: none;">
   Verify Email
</a>
```

---

## Testing Checklist

After configuring SMTP:

1. ✅ Run app: `./run_debug.sh`
2. ✅ Register with real email
3. ✅ Check inbox for verification email
4. ✅ Click link in email
5. ✅ App should open automatically
6. ✅ User should be verified and logged in

---

## Troubleshooting

### "Email not received"
- Check spam folder
- Verify SMTP credentials are correct
- Check SendGrid/Resend dashboard for errors
- Verify sender email is valid

### "Link doesn't open app"
- Check redirect URLs are saved in Supabase
- Make sure `coffeenance://verify-email` is in the list
- Restart simulator/device

### "Still shows not verified"
- Check terminal debug output: `./run_debug.sh`
- Look for: `flutter: 🔐 Email verified!`
- Check Supabase Users table - email_confirmed_at should have timestamp

---

## Quick Start (SendGrid - 5 minutes)

```bash
# 1. Get SendGrid API key (signup.sendgrid.com)
# 2. Configure in Supabase SMTP settings
# 3. Add redirect URLs
# 4. Test!

./run_debug.sh
# Register → Check email → Click link → Done!
```

---

## Cost Comparison

| Provider | Free Tier | Best For |
|----------|-----------|----------|
| **SendGrid** | 100/day forever | Production |
| **Resend** | 100/day forever | Modern apps |
| **Mailgun** | 5000/month (3 months) | High volume |
| **Gmail** | Unlimited | Testing only |

**Recommended: SendGrid** - Most reliable, free forever, easy setup.

---

## Your Deep Links Are Ready! 🎉

Once SMTP is configured, your email verification will work automatically:
- ✅ Deep link handler: `coffeenance://verify-email`
- ✅ Email verification screen
- ✅ Auto-redirect after verification
- ✅ Real-time auth state listening

Just add SMTP credentials and you're done!
