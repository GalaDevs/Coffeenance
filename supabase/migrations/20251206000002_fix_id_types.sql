-- Fix ID types from UUID to BIGSERIAL for Flutter app compatibility
-- This migration converts all UUID primary keys to integer BIGSERIAL

-- Drop all tables and recreate with correct ID types
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS kpi_settings CASCADE;
DROP TABLE IF EXISTS tax_settings CASCADE;

-- ============================================
-- TRANSACTIONS TABLE
-- ============================================
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

-- ============================================
-- INVENTORY TABLE
-- ============================================
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

-- ============================================
-- STAFF TABLE
-- ============================================
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

-- ============================================
-- KPI SETTINGS TABLE
-- ============================================
CREATE TABLE kpi_settings (
    id BIGSERIAL PRIMARY KEY,
    setting_key TEXT UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_kpi_settings_key ON kpi_settings(setting_key);

-- ============================================
-- TAX SETTINGS TABLE
-- ============================================
CREATE TABLE tax_settings (
    id BIGSERIAL PRIMARY KEY,
    setting_key TEXT UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_tax_settings_key ON tax_settings(setting_key);

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

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_staff_updated_at BEFORE UPDATE ON staff
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kpi_settings_updated_at BEFORE UPDATE ON kpi_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tax_settings_updated_at BEFORE UPDATE ON tax_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_settings ENABLE ROW LEVEL SECURITY;

-- Permissive policies for all operations
CREATE POLICY "Enable all operations for all users" ON transactions FOR ALL USING (true);
CREATE POLICY "Enable all operations for all users" ON inventory FOR ALL USING (true);
CREATE POLICY "Enable all operations for all users" ON staff FOR ALL USING (true);
CREATE POLICY "Enable all operations for all users" ON kpi_settings FOR ALL USING (true);
CREATE POLICY "Enable all operations for all users" ON tax_settings FOR ALL USING (true);

-- ============================================
-- ENABLE REALTIME REPLICATION
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE inventory;
ALTER PUBLICATION supabase_realtime ADD TABLE staff;
ALTER PUBLICATION supabase_realtime ADD TABLE kpi_settings;
ALTER PUBLICATION supabase_realtime ADD TABLE tax_settings;
