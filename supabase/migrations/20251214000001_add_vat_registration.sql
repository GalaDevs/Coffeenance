-- Add VAT registration field to shop_settings table
-- Migration: 20251214000001_add_vat_registration.sql

-- Add is_vat_registered column to shop_settings table
ALTER TABLE public.shop_settings
ADD COLUMN IF NOT EXISTS is_vat_registered BOOLEAN DEFAULT false NOT NULL;

-- Update existing records to false by default
UPDATE public.shop_settings
SET is_vat_registered = false
WHERE is_vat_registered IS NULL;

-- Verify the column was added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'shop_settings'
  AND column_name = 'is_vat_registered';
