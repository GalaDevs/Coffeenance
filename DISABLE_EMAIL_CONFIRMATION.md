# How to Disable Email Confirmation in Supabase

## Problem
- User registration creates accounts but requires email confirmation
- SMTP is not configured, so no emails are sent
- Users can't login because their email isn't confirmed

## Solution - Disable Email Confirmation

### Step 1: Open Supabase Dashboard
1. Go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut
2. Login to your account

### Step 2: Disable Email Confirmation
1. Click on **"Authentication"** in the left sidebar
2. Click on **"Providers"** 
3. Find **"Email"** provider
4. Click to expand Email settings
5. **UNCHECK** "Confirm email"
6. Click **"Save"**

### Step 3: Check Existing Users
1. Go to **Authentication** > **Users**
2. Find user: `rheysehmac@gmail.com`
3. If the user exists:
   - Click on the user
   - Look for "Email Confirmed" field
   - If it's `false`, manually set it to `true` by clicking the toggle

### Step 4: Test Login
1. Stop the app (Ctrl+C in terminal)
2. Run: `./run_debug.sh`
3. Try logging in with the email you registered

## Alternative: Configure SMTP (Production)

If you want email verification for production:

### Option 1: Use Supabase SMTP (Recommended)
1. Authentication > Settings > SMTP Settings
2. Enable custom SMTP
3. Use a service like:
   - **SendGrid** (Free tier: 100 emails/day)
   - **Resend** (Free tier: 100 emails/day)
   - **Mailgun** (Free tier: 100 emails/day)

### Option 2: Use Default Supabase Emails
1. Keep email confirmation enabled
2. Supabase will send emails from their domain
3. Limited to development/testing only

## Quick Fix SQL (Run in Supabase SQL Editor)

If you want to manually confirm existing users:

```sql
-- Confirm all existing users
UPDATE auth.users 
SET email_confirmed_at = NOW(),
    confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

-- Check results
SELECT email, email_confirmed_at, confirmed_at 
FROM auth.users;
```

## Current Status
- ✅ User accounts ARE being created
- ❌ Email confirmation is blocking login
- ❌ SMTP not configured (no emails sent)

## Recommended Action
**Disable email confirmation** for now so you can test the app.
Enable it later when you configure SMTP for production.
