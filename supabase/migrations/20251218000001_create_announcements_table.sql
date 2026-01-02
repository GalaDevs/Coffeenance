-- Create Announcements Table for Developer Broadcast Messages
-- Only developers can create announcements, all users can view them

CREATE TABLE IF NOT EXISTS announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    announced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_is_active ON announcements(is_active);

-- Enable Row Level Security
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view active announcements
CREATE POLICY "anyone_can_view_active_announcements"
    ON announcements FOR SELECT
    USING (is_active = true);

-- Policy: Only developers can insert announcements
CREATE POLICY "developers_can_insert_announcements"
    ON announcements FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role = 'developer'
        )
    );

-- Policy: Only developers can update announcements
CREATE POLICY "developers_can_update_announcements"
    ON announcements FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role = 'developer'
        )
    );

-- Policy: Only developers can delete announcements
CREATE POLICY "developers_can_delete_announcements"
    ON announcements FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid()
            AND role = 'developer'
        )
    );

-- Enable realtime for announcements
ALTER PUBLICATION supabase_realtime ADD TABLE announcements;
