-- Add announced_at column to announcements table
ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS announced_at TIMESTAMP WITH TIME ZONE;
