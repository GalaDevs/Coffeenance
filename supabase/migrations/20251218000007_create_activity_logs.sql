-- Create Activity Logs Table
-- Tracks all revenue and expense additions by users
-- Only visible to admins within their circle

CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    user_role TEXT NOT NULL CHECK (user_role IN ('admin', 'manager', 'staff', 'developer')),
    action_type TEXT NOT NULL CHECK (action_type IN ('add_revenue', 'add_expense', 'edit_transaction', 'delete_transaction')),
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    transaction_type TEXT CHECK (transaction_type IN ('revenue', 'expense')),
    amount NUMERIC(15, 2),
    category TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_activity_logs_admin_id ON activity_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action_type ON activity_logs(action_type);

-- Enable Row Level Security
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Only admins can view activity logs in their circle
CREATE POLICY "admins_can_view_activity_logs"
    ON activity_logs FOR SELECT
    USING (
        admin_id = (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
        AND
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role IN ('admin', 'developer')
        )
    );

-- Policy: All authenticated users can insert activity logs (system will validate)
CREATE POLICY "users_can_insert_activity_logs"
    ON activity_logs FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND admin_id = (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
    );

-- Enable realtime for activity logs
ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS activity_logs;

-- Comment
COMMENT ON TABLE activity_logs IS 'Activity logs for tracking revenue and expense additions by users';
COMMENT ON COLUMN activity_logs.admin_id IS 'Admin who owns this activity log entry';
COMMENT ON COLUMN activity_logs.user_id IS 'User who performed the action';
COMMENT ON COLUMN activity_logs.user_name IS 'Name of user for display purposes';
COMMENT ON COLUMN activity_logs.action_type IS 'Type of action performed';
COMMENT ON COLUMN activity_logs.transaction_type IS 'Type of transaction (revenue or expense)';
