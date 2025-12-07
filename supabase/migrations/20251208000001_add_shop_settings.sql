-- Add shop settings table for storing business information
-- Each admin user can have their own shop settings

CREATE TABLE IF NOT EXISTS public.shop_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shop_name TEXT NOT NULL DEFAULT 'CoffeeFlow Coffee Shop',
  location_address TEXT,
  location_latitude DECIMAL(10, 8),
  location_longitude DECIMAL(11, 8),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(admin_id)
);

-- Enable RLS
ALTER TABLE public.shop_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own shop settings
-- Admin can view/edit their own settings
CREATE POLICY "Users can view their own shop settings"
  ON public.shop_settings
  FOR SELECT
  USING (
    admin_id = auth.uid() OR
    admin_id IN (
      SELECT admin_id FROM public.user_profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can insert their own shop settings"
  ON public.shop_settings
  FOR INSERT
  WITH CHECK (admin_id = auth.uid());

CREATE POLICY "Users can update their shop settings"
  ON public.shop_settings
  FOR UPDATE
  USING (
    admin_id = auth.uid() OR
    admin_id IN (
      SELECT admin_id FROM public.user_profiles WHERE id = auth.uid()
    )
  );

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_shop_settings_admin_id ON public.shop_settings(admin_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_shop_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER shop_settings_updated_at
  BEFORE UPDATE ON public.shop_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_shop_settings_updated_at();

-- Insert default settings for existing admins
INSERT INTO public.shop_settings (admin_id, shop_name)
SELECT id, 'CoffeeFlow Coffee Shop'
FROM public.user_profiles
WHERE role = 'admin'
ON CONFLICT (admin_id) DO NOTHING;
