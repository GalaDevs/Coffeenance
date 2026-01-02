-- Add announcement to notification type check constraint
-- Drop the existing check constraint
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;

-- Add new check constraint that includes 'announcement'
ALTER TABLE notifications ADD CONSTRAINT notifications_type_check 
  CHECK (type IN ('transaction_deleted', 'edit_request', 'edit_approved', 'edit_rejected', 'announcement'));
