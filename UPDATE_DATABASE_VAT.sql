-- ============================================
-- RUN THIS IN SUPABASE SQL EDITOR
-- Add VAT Registration to Shop Settings
-- ============================================

-- Add is_vat_registered column to shop_settings table
ALTER TABLE public.shop_settings
ADD COLUMN IF NOT EXISTS is_vat_registered BOOLEAN DEFAULT false NOT NULL;

-- Update existing records to false by default
UPDATE public.shop_settings
SET is_vat_registered = false
WHERE is_vat_registered IS NULL;

-- Verify the column was added
SELECT 
    'is_vat_registered column' as check_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.columns
            WHERE table_name = 'shop_settings'
              AND column_name = 'is_vat_registered'
        ) THEN '✅ Column exists'
        ELSE '❌ Column missing'
    END as status;

-- Show current shop_settings structure
SELECT 
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'shop_settings'
ORDER BY ordinal_position;
