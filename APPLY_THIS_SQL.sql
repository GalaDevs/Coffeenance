-- STEP 1: Copy this entire file
-- STEP 2: Go to Supabase Dashboard → SQL Editor → New Query
-- STEP 3: Paste and click RUN

-- Create KPI Targets Table
CREATE TABLE IF NOT EXISTS kpi_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    target_key TEXT NOT NULL,
    target_value DOUBLE PRECISION NOT NULL DEFAULT 0,
    month INTEGER,
    year INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(shop_id, target_key, month, year)
);

CREATE INDEX IF NOT EXISTS idx_kpi_targets_shop_id ON kpi_targets(shop_id);
CREATE INDEX IF NOT EXISTS idx_kpi_targets_user_id ON kpi_targets(user_id);
CREATE INDEX IF NOT EXISTS idx_kpi_targets_month_year ON kpi_targets(month, year);

ALTER TABLE kpi_targets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their shop's targets" ON kpi_targets FOR SELECT
USING (shop_id IN (SELECT COALESCE(admin_id, id) FROM user_profiles WHERE id = auth.uid()));

CREATE POLICY "Admins and managers can create targets" ON kpi_targets FOR INSERT
WITH CHECK (shop_id IN (SELECT COALESCE(admin_id, id) FROM user_profiles WHERE id = auth.uid() AND role IN ('admin', 'manager')));

CREATE POLICY "Admins and managers can update targets" ON kpi_targets FOR UPDATE
USING (shop_id IN (SELECT COALESCE(admin_id, id) FROM user_profiles WHERE id = auth.uid() AND role IN ('admin', 'manager')));

CREATE POLICY "Admins can delete targets" ON kpi_targets FOR DELETE
USING (shop_id IN (SELECT COALESCE(admin_id, id) FROM user_profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE OR REPLACE FUNCTION update_kpi_targets_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_kpi_targets_timestamp BEFORE UPDATE ON kpi_targets
FOR EACH ROW EXECUTE FUNCTION update_kpi_targets_updated_at();
