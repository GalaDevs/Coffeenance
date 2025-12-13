-- Create KPI Targets Table for Cloud-Based Target Storage
-- This table stores monthly revenue and transaction targets for each shop (admin)
-- Uses admin_id pattern consistent with other tables

-- Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS kpi_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL, -- References admin user ID (the team owner)
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

-- Helper function to get current user's admin_id (team owner)
-- This follows the same pattern as transactions and other tables
CREATE OR REPLACE FUNCTION get_kpi_targets_admin_id()
RETURNS UUID AS $$
DECLARE
    user_admin_id UUID;
    user_role TEXT;
BEGIN
    SELECT admin_id, role INTO user_admin_id, user_role
    FROM user_profiles
    WHERE id = auth.uid();
    
    -- If user is admin (admin_id is null), return their own id
    -- If user is staff/manager, return their admin_id
    IF user_role = 'admin' OR user_admin_id IS NULL THEN
        RETURN auth.uid();
    ELSE
        RETURN user_admin_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Policy: Team members can view their team's targets
CREATE POLICY "team_select_kpi_targets"
    ON kpi_targets FOR SELECT
    USING (shop_id = get_kpi_targets_admin_id());

-- Policy: Admins and managers can insert targets for their team
CREATE POLICY "team_insert_kpi_targets"
    ON kpi_targets FOR INSERT
    WITH CHECK (
        shop_id = get_kpi_targets_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager')
        )
    );

-- Policy: Admins and managers can update targets for their team
CREATE POLICY "team_update_kpi_targets"
    ON kpi_targets FOR UPDATE
    USING (
        shop_id = get_kpi_targets_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager')
        )
    );

-- Policy: Admins can delete targets for their team
CREATE POLICY "team_delete_kpi_targets"
    ON kpi_targets FOR DELETE
    USING (
        shop_id = get_kpi_targets_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles 
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

-- Create trigger only if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_kpi_targets_timestamp') THEN
        CREATE TRIGGER update_kpi_targets_timestamp
            BEFORE UPDATE ON kpi_targets
            FOR EACH ROW
            EXECUTE FUNCTION update_kpi_targets_updated_at();
    END IF;
END
$$;

COMMENT ON TABLE kpi_targets IS 'Stores KPI targets (revenue, transactions) for shops. Supports monthly planning and cloud sync across team members.';
