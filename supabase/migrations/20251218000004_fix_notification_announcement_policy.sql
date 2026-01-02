-- Fix notifications RLS to allow developers to create announcement notifications

-- First, let's see what policies exist and drop the conflicting one if needed
DROP POLICY IF EXISTS "developers_can_create_announcement_notifications" ON notifications;

-- Allow developers to insert announcement notifications for any user
CREATE POLICY "developers_can_insert_announcement_notifications"
    ON notifications FOR INSERT
    WITH CHECK (
        type = 'announcement' 
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role = 'developer'
        )
    );

-- Also ensure users can view their own notifications (if not already exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'notifications' 
        AND policyname = 'users_can_view_own_notifications'
    ) THEN
        CREATE POLICY "users_can_view_own_notifications"
            ON notifications FOR SELECT
            USING (user_id = auth.uid());
    END IF;
END $$;
