-- Add download_link column to announcements table
ALTER TABLE announcements ADD COLUMN IF NOT EXISTS download_link TEXT;

-- Add comment to the column
COMMENT ON COLUMN announcements.download_link IS 'Optional URL for downloadable content related to the announcement';
