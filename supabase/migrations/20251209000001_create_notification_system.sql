-- Create Notification and Approval System
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: Create notifications table
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    admin_id UUID,
    type TEXT NOT NULL CHECK (type IN ('transaction_deleted', 'edit_request', 'edit_approved', 'edit_rejected')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES user_profiles(id),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_admin_id ON notifications(admin_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- ============================================
-- STEP 2: Create pending transaction edits table
-- ============================================
CREATE TABLE IF NOT EXISTS pending_transaction_edits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id BIGINT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    admin_id UUID,
    original_data JSONB NOT NULL,
    edited_data JSONB NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    reviewed_by UUID REFERENCES user_profiles(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_pending_edits_transaction_id ON pending_transaction_edits(transaction_id);
CREATE INDEX IF NOT EXISTS idx_pending_edits_user_id ON pending_transaction_edits(user_id);
CREATE INDEX IF NOT EXISTS idx_pending_edits_admin_id ON pending_transaction_edits(admin_id);
CREATE INDEX IF NOT EXISTS idx_pending_edits_status ON pending_transaction_edits(status);

-- ============================================
-- STEP 3: Enable Row Level Security
-- ============================================
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE pending_transaction_edits ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 4: RLS Policies for notifications
-- ============================================

-- Users can view their own notifications
DROP POLICY IF EXISTS "Users can view their notifications" ON notifications;
CREATE POLICY "Users can view their notifications" ON notifications
    FOR SELECT
    USING (
        user_id = auth.uid() 
        AND admin_id IN (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
    );

-- Admins and managers can create notifications
DROP POLICY IF EXISTS "Admins and managers can create notifications" ON notifications;
CREATE POLICY "Admins and managers can create notifications" ON notifications
    FOR INSERT
    WITH CHECK (
        admin_id IN (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager')
        )
    );

-- Users can update their own notifications (mark as read)
DROP POLICY IF EXISTS "Users can update their notifications" ON notifications;
CREATE POLICY "Users can update their notifications" ON notifications
    FOR UPDATE
    USING (
        user_id = auth.uid()
        AND admin_id IN (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
    );

-- ============================================
-- STEP 5: RLS Policies for pending_transaction_edits
-- ============================================

-- Staff can view their own pending edits
-- Admins and managers can view all pending edits in their organization
DROP POLICY IF EXISTS "Users can view pending edits" ON pending_transaction_edits;
CREATE POLICY "Users can view pending edits" ON pending_transaction_edits
    FOR SELECT
    USING (
        admin_id IN (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
        AND (
            user_id = auth.uid() 
            OR EXISTS (
                SELECT 1 FROM user_profiles 
                WHERE id = auth.uid() 
                AND role IN ('admin', 'manager')
            )
        )
    );

-- Staff can create pending edits
DROP POLICY IF EXISTS "Staff can create pending edits" ON pending_transaction_edits;
CREATE POLICY "Staff can create pending edits" ON pending_transaction_edits
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND admin_id IN (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'staff'
        )
    );

-- Admins and managers can update pending edits (approve/reject)
DROP POLICY IF EXISTS "Admins and managers can update pending edits" ON pending_transaction_edits;
CREATE POLICY "Admins and managers can update pending edits" ON pending_transaction_edits
    FOR UPDATE
    USING (
        admin_id IN (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager')
        )
    );

-- ============================================
-- STEP 6: Enable Realtime
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE pending_transaction_edits;

-- ============================================
-- STEP 7: Create function to auto-update updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers
DROP TRIGGER IF EXISTS update_notifications_updated_at ON notifications;
CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_pending_edits_updated_at ON pending_transaction_edits;
CREATE TRIGGER update_pending_edits_updated_at
    BEFORE UPDATE ON pending_transaction_edits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 8: Create helper function to create notifications
-- ============================================
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_admin_id UUID,
    p_type TEXT,
    p_title TEXT,
    p_message TEXT,
    p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO notifications (user_id, admin_id, type, title, message, data, created_by)
    VALUES (p_user_id, p_admin_id, p_type, p_title, p_message, p_data, auth.uid())
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_notification TO authenticated;

COMMENT ON TABLE notifications IS 'Stores notifications for transaction deletions and edit approvals';
COMMENT ON TABLE pending_transaction_edits IS 'Stores pending transaction edit requests from staff members';
