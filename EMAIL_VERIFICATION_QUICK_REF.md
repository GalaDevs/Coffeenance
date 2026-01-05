# 📧 Email Verification - Quick Reference

## ✅ What's Implemented

- ✅ Deep link support (`coffeenance://verify-email`)
- ✅ Automatic email verification on signup
- ✅ Login blocked for unverified users
- ✅ Auto-detection of verification via deep link
- ✅ Resend email with cooldown
- ✅ User-friendly error messages
- ✅ Production-ready code

---

## 🔧 Supabase Dashboard Setup (3 Steps)

### 1. Enable Email Confirmation
**URL:** https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/providers

1. Click **Email** provider
2. Check: ☑ **Confirm email**
3. Click **Save**

### 2. Add Redirect URLs
**URL:** https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/url-configuration

**Site URL:**
```
coffeenance://verify-email
```

**Redirect URLs (add all):**
```
coffeenance://verify-email
coffeenance://**
https://tpejvjznleoinsanrgut.supabase.co/**
```

### 3. Custom SMTP (Optional - For Production)
**URL:** https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/settings/auth

**Recommended: SendGrid**
- Free tier: 100k emails/month
- Sign up: https://sendgrid.com

**Settings:**
```
SMTP Host: smtp.sendgrid.net
SMTP Port: 587
SMTP User: apikey
SMTP Pass: <your-sendgrid-api-key>
Sender Email: noreply@yourdomain.com
Sender Name: Coffeenance
```

---

## 🧪 Testing Checklist

### Test 1: Register New User
```bash
flutter run -d "Rhey"
```
1. Click "Create Account"
2. Fill in details with **real email**
3. Submit form
4. ✅ Check email inbox
5. ✅ Click verification link
6. ✅ App should show "Email verified!"

### Test 2: Login with Unverified Email
1. Register but don't verify
2. Try to login
3. ✅ Should show verification screen
4. ✅ Resend button should work
5. ✅ 60-second cooldown should activate

### Test 3: Deep Link
**iOS:**
```bash
xcrun simctl openurl booted "coffeenance://verify-email"
```

**Android:**
```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "coffeenance://verify-email" com.example.coffeeflow
```

---

## 🚨 Common Issues & Solutions

### Issue: "Email not sent"

**Check:**
1. Supabase Auth logs: **Authentication** → **Logs**
2. SMTP configuration
3. Email in spam folder

**Fix:**
- Use custom SMTP (SendGrid)
- Check sender email is valid

### Issue: "Deep link not working"

**Android:**
```bash
# Check if intent filter registered
adb shell dumpsys package com.example.coffeeflow | grep "coffeenance"

# Should show: scheme="coffeenance"
```

**iOS:**
```bash
# Check URL types in Info.plist
plutil -p ios/Runner/Info.plist | grep -A 5 CFBundleURLTypes
```

### Issue: "Still says email not verified"

**Manual Fix in Supabase SQL Editor:**
```sql
UPDATE auth.users 
SET email_confirmed_at = NOW()
WHERE email = 'your-email@example.com';
```

---

## 📱 User Experience

### Registration
1. User registers → **"Check your email"** message
2. Opens email → Clicks link
3. App opens automatically → **"Email verified!"**
4. Can now login → Full access

### Login (Unverified)
1. User tries to login
2. Shows error: "Please verify your email"
3. Auto-navigates to verification screen
4. New email sent automatically
5. User verifies → Returns to login

---

## 📁 Modified Files

```
✅ lib/main.dart                          # Deep link handling
✅ lib/services/auth_service.dart         # Email check
✅ lib/screens/email_verification_screen.dart  # New UI
✅ android/app/src/main/AndroidManifest.xml   # Deep links
✅ ios/Runner/Info.plist                  # URL schemes
```

---

## 🔗 Important Links

- **Supabase Auth:** https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/users
- **Email Logs:** https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/logs  
- **SMTP Settings:** https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/settings/auth
- **Full Guide:** `docs/EMAIL_VERIFICATION_COMPLETE.md`

---

## ⚡ Quick Commands

**Run on iPhone:**
```bash
flutter run -d "Rhey"
```

**Check for errors:**
```bash
flutter analyze
```

**Test deep link (iOS):**
```bash
xcrun simctl openurl booted "coffeenance://verify-email"
```

**Manual verify in Supabase:**
```sql
-- Run in SQL Editor
UPDATE auth.users SET email_confirmed_at = NOW() 
WHERE email = 'your@email.com';
```

---

**Status:** ✅ READY TO USE

Just configure Supabase settings and test!
