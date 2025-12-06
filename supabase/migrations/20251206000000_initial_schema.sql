-- Coffeenance Database Schema
-- Created: 2025-12-06
-- Description: Complete database schema for coffee shop management

-- ============================================
-- TRANSACTIONS TABLE
-- ============================================
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'transactions') THEN
        CREATE TABLE transactions (
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
        
        CREATE INDEX idx_transactions_date ON transactions(date DESC);
        CREATE INDEX idx_transactions_type ON transactions(type);
        CREATE INDEX idx_transactions_category ON transactions(category);
        CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);
    END IF;
END $$;

-- ============================================
-- INVENTORY TABLE
-- ============================================
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'inventory') THEN
        CREATE TABLE inventory (
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
        
        CREATE INDEX idx_inventory_category ON inventory(category);
        CREATE INDEX idx_inventory_name ON inventory(name);
    END IF;
END $$;

-- ============================================
-- STAFF TABLE
-- ============================================
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'staff') THEN
        CREATE TABLE staff (
            id BIGSERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            position TEXT DEFAULT '',
            hourly_rate NUMERIC(12, 2) DEFAULT 0,
            monthly_salary NUMERIC(12, 2) DEFAULT 0,
            contact TEXT DEFAULT '',
            email TEXT DEFAULT '',
            hire_date DATE,
            status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'terminated')),
            notes TEXT DEFAULT '',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX idx_staff_status ON staff(status);
        CREATE INDEX idx_staff_name ON staff(name);
    END IF;
END $$;

-- ============================================
-- KPI SETTINGS TABLE
-- ============================================
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'kpi_settings') THEN
        CREATE TABLE kpi_settings (
            id BIGSERIAL PRIMARY KEY,
            setting_key TEXT UNIQUE NOT NULL,
            setting_value JSONB NOT NULL,
            description TEXT DEFAULT '',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX idx_kpi_settings_key ON kpi_settings(setting_key);
    END IF;
END $$;

-- ============================================
-- TAX SETTINGS TABLE
-- ============================================
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'tax_settings') THEN
        CREATE TABLE tax_settings (
            id BIGSERIAL PRIMARY KEY,
            setting_key TEXT UNIQUE NOT NULL,
            setting_value JSONB NOT NULL,
            description TEXT DEFAULT '',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX idx_tax_settings_key ON tax_settings(setting_key);
    END IF;
END $$;

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    -- Transactions trigger
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_transactions_updated_at') THEN
        CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- Inventory trigger
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_inventory_updated_at') THEN
        CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- Staff trigger
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_staff_updated_at') THEN
        CREATE TRIGGER update_staff_updated_at BEFORE UPDATE ON staff
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- KPI settings trigger
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_kpi_settings_updated_at') THEN
        CREATE TRIGGER update_kpi_settings_updated_at BEFORE UPDATE ON kpi_settings
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- Tax settings trigger
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_tax_settings_updated_at') THEN
        CREATE TRIGGER update_tax_settings_updated_at BEFORE UPDATE ON tax_settings
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_settings ENABLE ROW LEVEL SECURITY;

-- Drop and recreate policies
DO $$
BEGIN
    -- Transactions policies
    DROP POLICY IF EXISTS "Enable all operations for all users" ON transactions;
    CREATE POLICY "Enable all operations for all users" ON transactions FOR ALL USING (true);
    
    -- Inventory policies
    DROP POLICY IF EXISTS "Enable all operations for all users" ON inventory;
    CREATE POLICY "Enable all operations for all users" ON inventory FOR ALL USING (true);
    
    -- Staff policies
    DROP POLICY IF EXISTS "Enable all operations for all users" ON staff;
    CREATE POLICY "Enable all operations for all users" ON staff FOR ALL USING (true);
    
    -- KPI settings policies
    DROP POLICY IF EXISTS "Enable all operations for all users" ON kpi_settings;
    CREATE POLICY "Enable all operations for all users" ON kpi_settings FOR ALL USING (true);
    
    -- Tax settings policies
    DROP POLICY IF EXISTS "Enable all operations for all users" ON tax_settings;
    CREATE POLICY "Enable all operations for all users" ON tax_settings FOR ALL USING (true);
END $$;

-- ============================================
-- ENABLE REALTIME REPLICATION
-- ============================================
-- Enable realtime for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE inventory;
ALTER PUBLICATION supabase_realtime ADD TABLE staff;
ALTER PUBLICATION supabase_realtime ADD TABLE kpi_settings;
ALTER PUBLICATION supabase_realtime ADD TABLE tax_settings;

