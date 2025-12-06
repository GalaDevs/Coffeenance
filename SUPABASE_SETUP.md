# Supabase Setup Complete! 🎉

Your Coffeenance app is now connected to Supabase! Here's what's been set up:

## ✅ What's Done

1. **Supabase Flutter SDK** installed and initialized
2. **Configuration** added with your project credentials
3. **Database Schema** created (migration file ready)
4. **Supabase Service** layer for all CRUD operations
5. **TransactionProvider** updated to sync with Supabase
6. **Migration Helper** for syncing local data

## 🗄️ Database Setup (IMPORTANT!)

You need to manually create the tables in Supabase. Go to your SQL Editor:

**👉 https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/sql/new**

Then copy and paste this SQL:

\`\`\`sql
-- Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
    id BIGSERIAL PRIMARY KEY,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    type TEXT NOT NULL CHECK (type IN ('revenue', 'transaction', 'income', 'expense')),
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    payment_method TEXT DEFAULT '',
    transaction_number TEXT DEFAULT '',
    receipt_number TEXT DEFAULT '',
    tin_number TEXT DEFAULT '',
    vat INTEGER DEFAULT 0,
    supplier_name TEXT DEFAULT '',
    supplier_address TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inventory Table
CREATE TABLE IF NOT EXISTS inventory (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT DEFAULT '',
    quantity NUMERIC(12, 2) DEFAULT 0,
    unit TEXT DEFAULT '',
    unit_cost NUMERIC(12, 2) DEFAULT 0,
    total_cost NUMERIC(12, 2) DEFAULT 0,
    supplier TEXT DEFAULT '',
    reorder_level NUMERIC(12, 2) DEFAULT 0,
    notes TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Staff Table
CREATE TABLE IF NOT EXISTS staff (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    position TEXT DEFAULT '',
    hourly_rate NUMERIC(12, 2) DEFAULT 0,
    monthly_salary NUMERIC(12, 2) DEFAULT 0,
    contact TEXT DEFAULT '',
    email TEXT DEFAULT '',
    hire_date DATE,
    status TEXT DEFAULT 'active',
    notes TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- KPI Settings Table
CREATE TABLE IF NOT EXISTS kpi_settings (
    id BIGSERIAL PRIMARY KEY,
    setting_key TEXT UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tax Settings Table  
CREATE TABLE IF NOT EXISTS tax_settings (
    id BIGSERIAL PRIMARY KEY,
    setting_key TEXT UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_settings ENABLE ROW LEVEL SECURITY;

-- Create policies (allow all operations for now)
CREATE POLICY "Enable all operations for all users" ON transactions FOR ALL USING (true);
CREATE POLICY "Enable all operations for all users" ON inventory FOR ALL USING (true);
CREATE POLICY "Enable all operations for all users" ON staff FOR ALL USING (true);
CREATE POLICY "Enable all operations for all users" ON kpi_settings FOR ALL USING (true);
CREATE POLICY "Enable all operations for all users" ON tax_settings FOR ALL USING (true);
\`\`\`

## 📱 How It Works Now

### Automatic Cloud Sync
Every time you:
- **Add** a transaction → Saved to Supabase ✅
- **Update** a transaction → Updated in Supabase ✅
- **Delete** a transaction → Removed from Supabase ✅

### Offline Support
- If Supabase is unavailable, data saves **locally**
- When connection is restored, use refresh to sync

### On App Launch
- App tries to load from **Supabase first**
- Falls back to **local storage** if offline
- You always have your data! 🎉

## 🔄 Testing Your Connection

After creating the tables, restart your app:

\`\`\`bash
flutter run -d 00008130-000A60402E62001C
\`\`\`

Or on simulator:
\`\`\`bash
flutter run -d apple_ios_simulator
\`\`\`

## 💾 Where Data is Stored

1. **Supabase Cloud** (Primary) - Your PostgreSQL database
2. **Local Device** (Backup) - SharedPreferences cache

## 🔍 Check Your Data

View your data in Supabase:
- **Table Editor**: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/editor
- **SQL Editor**: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/sql

## 📊 Current Status

- ✅ Supabase connected
- ⏳ Database tables need to be created (run SQL above)
- ✅ App ready to sync data

**Next:** Create the tables using the SQL above, then test by adding a transaction in your app!
