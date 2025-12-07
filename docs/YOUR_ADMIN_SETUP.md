# 🎯 Quick Setup - Your Admin Account

## ✅ Your Login Credentials

**Email:** `theyieldcoffee@admin.com`  
**Password:** `Yield@2025`  
**Role:** Admin (Full Access)

---

## 📱 How to Create Your Account in Supabase

### Step 1: Create User in Supabase Dashboard
1. Open: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/users
2. Click **"Add User"** button
3. Fill in:
   - **Email:** `theyieldcoffee@admin.com`
   - **Password:** `Yield@2025`
   - **Auto Confirm User:** ✅ Check this box
4. Click **"Create User"**

### Step 2: Make User an Admin
1. Open: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/sql/new
2. Copy and paste this SQL:

```sql
-- Update user metadata
UPDATE auth.users 
SET raw_user_meta_data = jsonb_build_object(
    'role', 'admin',
    'full_name', 'TheYieldCoffee'
)
WHERE email = 'theyieldcoffee@admin.com';

-- Create admin profile
INSERT INTO user_profiles (id, email, full_name, role, is_active)
SELECT 
    id,
    email,
    'TheYieldCoffee',
    'admin',
    true
FROM auth.users
WHERE email = 'theyieldcoffee@admin.com'
ON CONFLICT (id) DO UPDATE
SET role = 'admin',
    full_name = 'TheYieldCoffee',
    is_active = true;
```

3. Click **"Run"**

### Step 3: Verify
Run this to confirm:
```sql
SELECT email, full_name, role, is_active 
FROM user_profiles 
WHERE email = 'theyieldcoffee@admin.com';
```

You should see your admin account listed.

---

## 📲 Login to Your iPhone App

Once the app is installed on your iPhone:

1. Open **Coffeenance** app
2. You'll see the login screen
3. Enter:
   - **Email:** `theyieldcoffee@admin.com`
   - **Password:** `Yield@2025`
4. Tap **"Sign In"**
5. ✅ You're in as Admin!

---

## 🎯 What You Can Do as Admin

- ✅ View Dashboard analytics
- ✅ Manage Revenue tracking
- ✅ Add/Edit/Delete Transactions
- ✅ Access Settings
- ✅ **Create Manager and Staff accounts** (Settings → User Management)
- ✅ Export/Import data
- ✅ Full system control

---

## 👥 Create Additional Accounts

After logging in:

1. Go to **Settings** tab
2. Tap **"User Management"**
3. Tap **"+ Add User"** button
4. Create:
   - **1 Manager** (access to all except Settings)
   - **2 Staff** (access to Transactions only)

---

## 🔐 Account Limits

- **Admin:** 1 (you)
- **Manager:** Maximum 1
- **Staff:** Maximum 2

Total: 4 users maximum

---

**Your app is being built and will be installed shortly!** 🚀
