-- ============================================
-- Custom Email Verification System
-- Independent of Supabase Auth email confirmation
-- ============================================

-- Create verification_codes table
CREATE TABLE IF NOT EXISTS verification_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    code VARCHAR(6) NOT NULL,
    verified BOOLEAN DEFAULT false,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    attempts INTEGER DEFAULT 0,
    UNIQUE(user_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_verification_codes_email ON verification_codes(email);
CREATE INDEX IF NOT EXISTS idx_verification_codes_user_id ON verification_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_codes_expires_at ON verification_codes(expires_at);

-- Enable RLS
ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own verification status
CREATE POLICY "Users can view own verification" ON verification_codes
    FOR SELECT
    USING (user_id = auth.uid());

-- Users can update their own verification (for marking as verified)
CREATE POLICY "Users can update own verification" ON verification_codes
    FOR UPDATE
    USING (user_id = auth.uid());

-- Service role can do everything (for backend operations)
CREATE POLICY "Service role full access" ON verification_codes
    FOR ALL
    USING (auth.role() = 'service_role');

-- Allow insert for authenticated users (when creating verification)
CREATE POLICY "Authenticated users can insert" ON verification_codes
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Add email_verified column to user_profiles if not exists
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;

-- Function to generate verification code
CREATE OR REPLACE FUNCTION generate_verification_code(p_user_id UUID, p_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_code TEXT;
BEGIN
    -- Generate 6-digit code
    v_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    
    -- Delete any existing codes for this user
    DELETE FROM verification_codes WHERE user_id = p_user_id;
    
    -- Insert new code (expires in 10 minutes)
    INSERT INTO verification_codes (user_id, email, code, expires_at)
    VALUES (p_user_id, p_email, v_code, NOW() + INTERVAL '10 minutes');
    
    RETURN v_code;
END;
$$;

-- Function to verify code
CREATE OR REPLACE FUNCTION verify_email_code(p_user_id UUID, p_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_valid BOOLEAN := false;
    v_attempts INTEGER;
BEGIN
    -- Check if code is valid and not expired
    SELECT 
        (code = p_code AND expires_at > NOW() AND NOT verified),
        attempts
    INTO v_valid, v_attempts
    FROM verification_codes
    WHERE user_id = p_user_id;
    
    IF v_valid IS NULL THEN
        RETURN false;
    END IF;
    
    -- Increment attempts
    UPDATE verification_codes 
    SET attempts = attempts + 1
    WHERE user_id = p_user_id;
    
    -- Check max attempts (5)
    IF v_attempts >= 5 THEN
        RETURN false;
    END IF;
    
    IF v_valid THEN
        -- Mark as verified
        UPDATE verification_codes 
        SET verified = true
        WHERE user_id = p_user_id;
        
        -- Update user profile
        UPDATE user_profiles 
        SET email_verified = true
        WHERE id = p_user_id;
        
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$;

-- Function to check if email is verified
CREATE OR REPLACE FUNCTION is_email_verified(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_verified BOOLEAN;
BEGIN
    SELECT email_verified INTO v_verified
    FROM user_profiles
    WHERE id = p_user_id;
    
    RETURN COALESCE(v_verified, false);
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION generate_verification_code TO authenticated;
GRANT EXECUTE ON FUNCTION verify_email_code TO authenticated;
GRANT EXECUTE ON FUNCTION is_email_verified TO authenticated;

-- ============================================
-- INSTRUCTIONS:
-- 1. Copy this entire file
-- 2. Go to Supabase Dashboard > SQL Editor
-- 3. Paste and click RUN
-- ============================================
