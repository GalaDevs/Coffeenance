# 🚀 Quick Reference - Authentication System

## One-Time Setup (Do This First!)

### 1. Create Admin Account in Supabase Dashboard
```
URL: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/users
Click: Add User
Email: admin@coffeenance.com
Password: [Your secure password]
Auto Confirm: ✅ YES
```

### 2. Make User an Admin (Run in SQL Editor)
```sql
UPDATE user_profiles 
SET role = 'admin', full_name = 'Admin User'
WHERE email = 'admin@coffeenance.com';
```

### 3. Verify
```sql
SELECT email, full_name, role FROM user_profiles WHERE role = 'admin';
```

---

## Daily Usage

### Login as Admin
1. Open app
2. Enter: `admin@coffeenance.com`
3. Enter your password
4. Click **Sign In**

### Create Staff/Manager
1. Login as Admin
2. Go to **Settings** tab
3. Tap **User Management**
4. Tap **+ Add User** button
5. Fill form:
   - Full Name
   - Email
   - Password (min 6 chars)
   - Role: Manager or Staff
6. Tap **Create**

### Logout
1. Go to **Settings** tab
2. Tap **Sign Out**
3. Confirm

---

## Account Limits

| Role | Max Count | Current |
|------|-----------|---------|
| Admin | 1 (manual) | Check in User Management |
| Manager | 1 | Shown in User Management |
| Staff | 2 | Shown in User Management |

---

## Role Permissions Quick View

```
STAFF:
✅ View Transactions
✅ Add Transactions
❌ Edit Transactions
❌ Delete Transactions
❌ View Analytics
❌ Access Settings

MANAGER:
✅ View Dashboard
✅ View Revenue Analytics
✅ View Transactions
✅ Add/Edit Transactions
✅ Manage Inventory
✅ Manage Payroll
❌ Delete Transactions
❌ Access Settings
❌ Manage Users

ADMIN:
✅ Everything Manager can do
✅ Access Settings
✅ Manage Users
✅ Delete Transactions
✅ Full System Control
```

---

## Troubleshooting

### Can't Login
- Check email/password correct
- Verify user exists in Supabase Dashboard
- Check `is_active` = true in database

### Can't Create Users
- Verify you're logged in as Admin
- Check account limits (1 manager, 2 staff)
- See error message for details

### Access Denied
- Role determines access
- Staff = Transactions only
- Manager = No Settings
- Admin = Full access

---

## Quick Commands

```bash
# Run app
flutter run

# Check database
supabase db execute "SELECT * FROM user_profiles;"

# View Supabase dashboard
open https://supabase.com/dashboard/project/tpejvjznleoinsanrgut
```

---

## Files Reference

- Setup Guide: `AUTHENTICATION_SETUP.md`
- Implementation: `AUTH_IMPLEMENTATION_SUMMARY.md`
- Admin SQL: `supabase/migrations/create_admin_user.sql`
- Migration: `supabase/migrations/20251206000003_create_users_and_auth.sql`

---

## Support

Check logs in:
1. Supabase Dashboard → Logs
2. Flutter console output
3. Supabase SQL Editor for queries

---

**Ready to go!** ☕🚀
