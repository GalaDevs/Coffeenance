-- Fix announcement RLS policies to allow developers full access

-- Drop existing policies
DROP POLICY IF EXISTS "anyone_can_view_active_announcements" ON announcements;
DROP POLICY IF EXISTS "developers_can_insert_announcements" ON announcements;
DROP POLICY IF EXISTS "developers_can_update_announcements" ON announcements;
DROP POLICY IF EXISTS "developers_can_delete_announcements" ON announcements;

-- Policy: Everyone can view active announcements
CREATE POLICY "anyone_can_view_active_announcements"
    ON announcements FOR SELECT
    USING (is_active = true);

-- Policy: Developers can view all announcements (including inactive)
CREATE POLICY "developers_can_view_all_announcements"
    ON announcements FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role = 'developer'
        )
    );

-- Policy: Developers can insert announcements
CREATE POLICY "developers_can_insert_announcements"
    ON announcements FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role = 'developer'
        )
    );

-- Policy: Developers can update all announcements
CREATE POLICY "developers_can_update_announcements"
    ON announcements FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role = 'developer'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role = 'developer'
        )
    );

-- Policy: Developers can delete announcements
CREATE POLICY "developers_can_delete_announcements"
    ON announcements FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role = 'developer'
        )
    );

-- Fix notifications table - allow developers to create notifications for announcements
DROP POLICY IF EXISTS "developers_can_create_announcement_notifications" ON notifications;

CREATE POLICY "developers_can_create_announcement_notifications"
    ON notifications FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role = 'developer'
        )
        AND type = 'announcement'
    );
