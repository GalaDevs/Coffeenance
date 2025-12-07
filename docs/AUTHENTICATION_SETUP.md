# 🔐 Authentication System Setup Guide

## Overview

Your Coffeenance app now has a complete role-based authentication system with 3 access levels:

1. **Admin** - Full access to all features + user management
2. **Manager** - Access to Dashboard, Revenue, Transactions (NO Settings)
3. **Staff** - Access to Transactions ONLY

---

## ✅ What's Been Implemented

### 1. Database Schema (Supabase)
- ✅ `user_profiles` table with role-based access control
- ✅ Row Level Security (RLS) policies
- ✅ Automatic profile creation on signup
- ✅ Account limits: 1 Manager, 2 Staff (enforced)

### 2. Flutter App Features
- ✅ Login screen with email/password
- ✅ User management screen (Admin only)
- ✅ Role-based navigation (different tabs per role)
- ✅ Settings with logout option
- ✅ Automatic session management
- ✅ Permission-based UI visibility

### 3. Access Control Matrix

| Feature | Admin | Manager | Staff |
|---------|-------|---------|-------|
| Dashboard | ✅ | ✅ | ❌ |
| Revenue | ✅ | ✅ | ❌ |
| Transactions | ✅ | ✅ | ✅ |
| Settings | ✅ | ❌ | ❌ |
| User Management | ✅ | ❌ | ❌ |
| Create Transactions | ✅ | ✅ | ✅ |
| Edit Transactions | ✅ | ✅ | ❌ |
| Delete Transactions | ✅ | ❌ | ❌ |
| Manage Inventory | ✅ | ✅ | ❌ |
| Manage Staff/Payroll | ✅ | ✅ | ❌ |

---

## 🚀 Setup Instructions

### Step 1: Create Your First Admin Account

You need to manually create the first admin account through Supabase Dashboard.

**Option A: Using Supabase Dashboard (Recommended)**

1. Go to your Supabase dashboard: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut
2. Click **Authentication** → **Users**
3. Click **Add User** button
4. Fill in the form:
   - Email: `admin@coffeenance.com` (or your preferred email)
   - Password: Create a strong password
   - Auto Confirm User: ✅ Enable
5. Click **Create User**
6. Now go to **SQL Editor** and run this query to make the user an admin:

```sql
-- Make the user an admin
UPDATE auth.users 
SET raw_user_meta_data = jsonb_build_object(
    'role', 'admin',
    'full_name', 'Admin User'
)
WHERE email = 'admin@coffeenance.com';

-- Also update the profile table
UPDATE user_profiles 
SET role = 'admin', 
    full_name = 'Admin User'
WHERE email = 'admin@coffeenance.com';
```

**Option B: Using SQL Only**

Run this in Supabase SQL Editor:

```sql
-- Create admin user with auth.users insert
-- Note: You'll need to hash the password or use Supabase dashboard

-- After creating via dashboard, update the role:
UPDATE user_profiles 
SET role = 'admin' 
WHERE email = 'your-admin-email@example.com';
```

### Step 2: Test the Login

1. Run your Flutter app
2. You should see the Login screen
3. Enter your admin email and password
4. Click "Sign In"
5. You should be redirected to the Dashboard

### Step 3: Create Staff and Manager Accounts

1. Login as Admin
2. Go to **Settings** tab
3. Click **User Management**
4. Click **Add User** (floating button)
5. Fill in the form:
   - Full Name: Employee name
   - Email: Their work email
   - Password: Temporary password (they can change later)
   - Role: Choose Manager or Staff
6. Click **Create**

**Account Limits:**
- Maximum **1 Manager** account
- Maximum **2 Staff** accounts
- These limits are enforced by the database

---

## 📱 How to Use

### As Admin:
1. Login with your admin credentials
2. You see all 4 tabs: Dashboard, Revenue, Transactions, Settings
3. In Settings, you can:
   - Manage users (create Manager/Staff)
   - Export/Import data
   - Change app settings
   - Sign out

### As Manager:
1. Login with manager credentials
2. You see 3 tabs: Dashboard, Revenue, Transactions
3. Can view all analytics and data
4. Can add/edit transactions
5. Cannot access Settings or user management

### As Staff:
1. Login with staff credentials
2. You see 1 tab: Transactions only
3. Can add new transactions
4. Cannot edit or delete transactions
5. Cannot view analytics or settings

---

## 🔧 Technical Details

### Files Created:
```
lib/models/user_profile.dart              - User model with roles
lib/services/auth_service.dart            - Authentication service
lib/providers/auth_provider.dart          - Auth state management
lib/screens/login_screen.dart             - Login UI
lib/screens/user_management_screen.dart   - User management UI
supabase/migrations/20251206000003_create_users_and_auth.sql - DB schema
```

### Files Modified:
```
lib/main.dart                 - Added AuthProvider and login flow
lib/screens/home_screen.dart  - Role-based navigation
lib/screens/settings_screen.dart - Added logout and user management
```

### Database Tables:
```sql
user_profiles (
  id UUID PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  role TEXT CHECK (role IN ('admin', 'manager', 'staff')),
  created_by UUID,
  is_active BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

---

## 🔒 Security Features

1. **Row Level Security (RLS)** - Database-level access control
2. **Password Hashing** - Handled by Supabase Auth
3. **JWT Sessions** - Automatic session management
4. **Permission Checks** - Both UI and API level
5. **Account Limits** - Enforced at database level

---

## 🐛 Troubleshooting

### "Login Failed" Error
- Check your Supabase anon key is correct in `lib/config/supabase_config.dart`
- Verify user exists in Supabase Dashboard → Authentication → Users
- Check user's role is set correctly in `user_profiles` table

### "Access Denied" in User Management
- Only Admin users can access User Management
- Verify your user's role is 'admin' in the database

### Cannot Create Manager/Staff
- Check if limits are reached (1 manager, 2 staff)
- Verify you're logged in as Admin
- Check Supabase logs for detailed errors

### User Not Logging In
- Clear app data and try again
- Check Supabase dashboard for auth errors
- Verify the user's `is_active` status is true

---

## 📝 Next Steps

1. ✅ Create your admin account
2. ✅ Login and test the app
3. ✅ Create manager account
4. ✅ Create 2 staff accounts
5. ✅ Test different role permissions
6. ✅ Distribute credentials to your team

---

## 🎯 Quick Start Commands

```bash
# Run the app
flutter run

# View Supabase tables
supabase db execute "SELECT * FROM user_profiles;"

# Check auth users
# Go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/users
```

---

## 📞 Support

If you encounter issues:
1. Check Supabase logs: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/logs/explorer
2. Review RLS policies in SQL Editor
3. Test authentication in Supabase Dashboard
4. Check Flutter logs for detailed error messages

---

**Your authentication system is now complete and ready to use!** 🎉
