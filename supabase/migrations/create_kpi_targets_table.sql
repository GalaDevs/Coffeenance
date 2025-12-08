-- Create KPI Targets Table for Cloud-Based Target Storage
-- This table stores monthly revenue and transaction targets for each shop
-- Allows sharing targets across devices and team members

CREATE TABLE IF NOT EXISTS kpi_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL, -- References admin user ID (each admin = one shop)
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    target_key TEXT NOT NULL,
    target_value DOUBLE PRECISION NOT NULL DEFAULT 0,
    month INTEGER, -- 1-12 for month-specific targets, NULL for general targets
    year INTEGER, -- Year for month-specific targets, NULL for general targets
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Ensure unique target per shop/key/month/year combination
    UNIQUE(shop_id, target_key, month, year)
);

-- Add indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_kpi_targets_shop_id ON kpi_targets(shop_id);
CREATE INDEX IF NOT EXISTS idx_kpi_targets_user_id ON kpi_targets(user_id);
CREATE INDEX IF NOT EXISTS idx_kpi_targets_month_year ON kpi_targets(month, year);

-- Enable Row Level Security
ALTER TABLE kpi_targets ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view targets for their shop
CREATE POLICY "Users can view their shop's targets"
    ON kpi_targets FOR SELECT
    USING (
        shop_id IN (
            SELECT shop_id FROM user_profiles WHERE id = auth.uid()
        )
    );

-- Policy: Admins and managers can insert targets for their shop
CREATE POLICY "Admins and managers can create targets"
    ON kpi_targets FOR INSERT
    WITH CHECK (
        shop_id IN (
            SELECT shop_id FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager')
        )
    );

-- Policy: Admins and managers can update targets for their shop
CREATE POLICY "Admins and managers can update targets"
    ON kpi_targets FOR UPDATE
    USING (
        shop_id IN (
            SELECT shop_id FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager')
        )
    );

-- Policy: Admins can delete targets for their shop
CREATE POLICY "Admins can delete targets"
    ON kpi_targets FOR DELETE
    USING (
        shop_id IN (
            SELECT shop_id FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_kpi_targets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on row update
CREATE TRIGGER update_kpi_targets_timestamp
    BEFORE UPDATE ON kpi_targets
    FOR EACH ROW
    EXECUTE FUNCTION update_kpi_targets_updated_at();

-- Insert default targets for existing shops (optional)
-- This will migrate any existing shops to have default KPI targets
COMMENT ON TABLE kpi_targets IS 'Stores KPI targets (revenue, transactions) for shops. Supports monthly planning and cloud sync across devices.';
