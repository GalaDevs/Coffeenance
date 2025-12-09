-- Fix: Rename owner_id columns to admin_id in notification tables

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their notifications" ON notifications;
DROP POLICY IF EXISTS "Admins and managers can create notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their notifications" ON notifications;
DROP POLICY IF EXISTS "Users can view pending edits" ON pending_transaction_edits;
DROP POLICY IF EXISTS "Staff can create pending edits" ON pending_transaction_edits;
DROP POLICY IF EXISTS "Admins and managers can update pending edits" ON pending_transaction_edits;

-- Rename columns if they exist as owner_id
DO $$ 
BEGIN
    -- Check and rename in notifications table
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notifications' AND column_name = 'owner_id'
    ) THEN
        ALTER TABLE notifications RENAME COLUMN owner_id TO admin_id;
    END IF;

    -- Check and rename in pending_transaction_edits table
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pending_transaction_edits' AND column_name = 'owner_id'
    ) THEN
        ALTER TABLE pending_transaction_edits RENAME COLUMN owner_id TO admin_id;
    END IF;
END $$;

-- Drop old indexes
DROP INDEX IF EXISTS idx_notifications_owner_id;
DROP INDEX IF EXISTS idx_pending_edits_owner_id;

-- Create new indexes
CREATE INDEX IF NOT EXISTS idx_notifications_admin_id ON notifications(admin_id);
CREATE INDEX IF NOT EXISTS idx_pending_edits_admin_id ON pending_transaction_edits(admin_id);

-- Recreate RLS policies with admin_id

-- Users can view their own notifications
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

-- Staff can view their own pending edits
-- Admins and managers can view all pending edits in their organization
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

-- Drop and recreate the create_notification function with admin_id
DROP FUNCTION IF EXISTS create_notification(UUID, UUID, TEXT, TEXT, TEXT, JSONB);

CREATE FUNCTION create_notification(
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
