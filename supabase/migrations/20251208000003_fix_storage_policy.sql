-- Fix storage policy for profile image uploads
-- Migration: 20251208000003_fix_storage_policy.sql

-- Drop the restrictive policy
DROP POLICY IF EXISTS "Users can upload their own profile images" ON storage.objects;

-- Allow all authenticated users to upload profile images
CREATE POLICY "Authenticated users can upload profile images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profiles' AND
  auth.role() = 'authenticated'
);

-- Also update the update and delete policies to be less restrictive
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;

CREATE POLICY "Authenticated users can update profile images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profiles' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Authenticated users can delete profile images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profiles' AND
  auth.role() = 'authenticated'
);
