-- =====================================================
-- Migration: 011_encrypt_sensitive_data.sql
-- Purpose: Encrypt sensitive data (bank accounts, RRN)
-- Description: Uses pgcrypto for column-level encryption
--              of PII and financial data
-- =====================================================

-- Enable pgcrypto extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================
-- 1. CREATE ENCRYPTION KEY MANAGEMENT
-- =====================================================

-- Store encryption key reference (actual key in Vault/env)
-- This table stores metadata about encryption, not the actual key
CREATE TABLE IF NOT EXISTS public.encryption_metadata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key_id TEXT NOT NULL UNIQUE,
  algorithm TEXT NOT NULL DEFAULT 'aes-256-gcm',
  created_at TIMESTAMPTZ DEFAULT now(),
  rotated_at TIMESTAMPTZ,
  active BOOLEAN DEFAULT true
);

-- Insert initial key reference
INSERT INTO encryption_metadata (key_id, algorithm, active)
VALUES ('primary_key_v1', 'aes-256-gcm', true)
ON CONFLICT (key_id) DO NOTHING;

-- =====================================================
-- 2. CREATE ENCRYPTION/DECRYPTION FUNCTIONS
-- =====================================================

-- Encrypt sensitive text data
CREATE OR REPLACE FUNCTION encrypt_sensitive(
  p_plaintext TEXT,
  p_key_id TEXT DEFAULT 'primary_key_v1'
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_key TEXT;
  v_encrypted BYTEA;
BEGIN
  -- Get encryption key from environment
  -- In production, this should come from Vault or secure key management
  v_key := current_setting('app.encryption_key', true);

  -- Fallback for development (should NEVER be used in production)
  IF v_key IS NULL OR v_key = '' THEN
    v_key := COALESCE(
      current_setting('app.encryption_key_' || p_key_id, true),
      'DEVELOPMENT_KEY_DO_NOT_USE_IN_PRODUCTION_32B!'
    );
  END IF;

  -- Return NULL for NULL input
  IF p_plaintext IS NULL THEN
    RETURN NULL;
  END IF;

  -- Encrypt using pgcrypto AES
  v_encrypted := pgp_sym_encrypt(
    p_plaintext,
    v_key,
    'cipher-algo=aes256'
  );

  -- Return base64 encoded with key_id prefix for key rotation support
  RETURN p_key_id || ':' || encode(v_encrypted, 'base64');
END;
$$;

-- Decrypt sensitive text data
CREATE OR REPLACE FUNCTION decrypt_sensitive(p_encrypted TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_key_id TEXT;
  v_key TEXT;
  v_encrypted_data TEXT;
  v_decrypted TEXT;
BEGIN
  -- Return NULL for NULL input
  IF p_encrypted IS NULL THEN
    RETURN NULL;
  END IF;

  -- Extract key_id and encrypted data
  IF position(':' IN p_encrypted) > 0 THEN
    v_key_id := split_part(p_encrypted, ':', 1);
    v_encrypted_data := substr(p_encrypted, length(v_key_id) + 2);
  ELSE
    -- Legacy data without key_id prefix
    v_key_id := 'primary_key_v1';
    v_encrypted_data := p_encrypted;
  END IF;

  -- Get decryption key
  v_key := current_setting('app.encryption_key', true);

  IF v_key IS NULL OR v_key = '' THEN
    v_key := COALESCE(
      current_setting('app.encryption_key_' || v_key_id, true),
      'DEVELOPMENT_KEY_DO_NOT_USE_IN_PRODUCTION_32B!'
    );
  END IF;

  -- Decrypt using pgcrypto
  BEGIN
    v_decrypted := pgp_sym_decrypt(
      decode(v_encrypted_data, 'base64'),
      v_key
    );
    RETURN v_decrypted;
  EXCEPTION WHEN OTHERS THEN
    -- Log decryption failure (but don't expose error details)
    RAISE WARNING 'Decryption failed for data with key_id: %', v_key_id;
    RETURN NULL;
  END;
END;
$$;

-- Mask sensitive data for display (show last 4 chars)
CREATE OR REPLACE FUNCTION mask_sensitive(p_encrypted TEXT, p_visible_chars INT DEFAULT 4)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_decrypted TEXT;
  v_length INT;
BEGIN
  IF p_encrypted IS NULL THEN
    RETURN NULL;
  END IF;

  v_decrypted := decrypt_sensitive(p_encrypted);

  IF v_decrypted IS NULL THEN
    RETURN '****';
  END IF;

  v_length := length(v_decrypted);

  IF v_length <= p_visible_chars THEN
    RETURN repeat('*', v_length);
  END IF;

  RETURN repeat('*', v_length - p_visible_chars) || right(v_decrypted, p_visible_chars);
END;
$$;

-- =====================================================
-- 3. ADD ENCRYPTED COLUMNS TO CREATOR_PROFILES
-- =====================================================

-- Add new encrypted columns
ALTER TABLE creator_profiles
  ADD COLUMN IF NOT EXISTS bank_account_number_encrypted TEXT,
  ADD COLUMN IF NOT EXISTS resident_registration_number_encrypted TEXT;

-- =====================================================
-- 4. MIGRATE EXISTING DATA (if any)
-- =====================================================

-- Migrate existing plaintext data to encrypted columns
DO $$
BEGIN
  -- Encrypt existing bank account numbers
  UPDATE creator_profiles
  SET bank_account_number_encrypted = encrypt_sensitive(bank_account_number)
  WHERE bank_account_number IS NOT NULL
    AND bank_account_number_encrypted IS NULL;

  -- Encrypt existing resident registration numbers
  UPDATE creator_profiles
  SET resident_registration_number_encrypted = encrypt_sensitive(resident_registration_number)
  WHERE resident_registration_number IS NOT NULL
    AND resident_registration_number_encrypted IS NULL;
END $$;

-- =====================================================
-- 5. CREATE SECURE VIEWS FOR ACCESS
-- =====================================================

-- View that shows masked sensitive data (for admin dashboards)
CREATE OR REPLACE VIEW creator_profiles_masked AS
SELECT
  id,
  user_id,
  channel_id,
  stage_name,
  stage_name_en,
  profile_image_url,
  cover_image_url,
  short_bio,
  full_bio,
  category,
  tags,
  social_links,
  onboarding_completed,
  verification_status,
  verified_at,
  -- Masked sensitive fields
  bank_code,
  bank_name,
  mask_sensitive(bank_account_number_encrypted, 4) AS bank_account_number_masked,
  account_holder_name,
  mask_sensitive(resident_registration_number_encrypted, 4) AS resident_registration_number_masked,
  business_registration_number,
  -- Other fields
  withholding_tax_rate,
  tax_type,
  payout_verified,
  payout_verified_at,
  total_subscribers,
  total_messages_sent,
  total_revenue_dt,
  total_revenue_krw,
  created_at,
  updated_at
FROM creator_profiles;

-- =====================================================
-- 6. SECURE FUNCTIONS FOR PAYOUT PROCESSING
-- =====================================================

-- Function to get decrypted payout info (for authorized payout processing only)
CREATE OR REPLACE FUNCTION get_creator_payout_info(p_creator_user_id UUID)
RETURNS TABLE (
  bank_code TEXT,
  bank_name TEXT,
  bank_account_number TEXT,
  account_holder_name TEXT,
  resident_registration_number TEXT,
  tax_type TEXT,
  withholding_tax_rate NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if caller has payout permission
  IF NOT (
    -- Is the creator themselves
    auth.uid() = p_creator_user_id
    OR
    -- Or has admin role
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
    OR
    -- Or is a manager with payout permission
    has_creator_permission(auth.uid(), p_creator_user_id, 'payout')
  ) THEN
    RAISE EXCEPTION 'Access denied: insufficient permissions for payout info';
  END IF;

  RETURN QUERY
  SELECT
    cp.bank_code,
    cp.bank_name,
    decrypt_sensitive(cp.bank_account_number_encrypted) AS bank_account_number,
    cp.account_holder_name,
    decrypt_sensitive(cp.resident_registration_number_encrypted) AS resident_registration_number,
    cp.tax_type,
    cp.withholding_tax_rate
  FROM creator_profiles cp
  WHERE cp.user_id = p_creator_user_id
    AND cp.payout_verified = true;
END;
$$;

-- Function to update encrypted payout info
CREATE OR REPLACE FUNCTION update_creator_payout_info(
  p_creator_user_id UUID,
  p_bank_code TEXT,
  p_bank_name TEXT,
  p_bank_account_number TEXT,
  p_account_holder_name TEXT,
  p_resident_registration_number TEXT DEFAULT NULL,
  p_business_registration_number TEXT DEFAULT NULL,
  p_tax_type TEXT DEFAULT 'individual'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only the creator themselves can update payout info
  IF auth.uid() != p_creator_user_id THEN
    RAISE EXCEPTION 'Access denied: only the creator can update payout info';
  END IF;

  UPDATE creator_profiles
  SET
    bank_code = p_bank_code,
    bank_name = p_bank_name,
    bank_account_number_encrypted = encrypt_sensitive(p_bank_account_number),
    account_holder_name = p_account_holder_name,
    resident_registration_number_encrypted = CASE
      WHEN p_resident_registration_number IS NOT NULL
      THEN encrypt_sensitive(p_resident_registration_number)
      ELSE resident_registration_number_encrypted
    END,
    business_registration_number = COALESCE(p_business_registration_number, business_registration_number),
    tax_type = p_tax_type,
    payout_verified = false, -- Reset verification when info changes
    payout_verified_at = NULL,
    updated_at = now()
  WHERE user_id = p_creator_user_id;

  RETURN FOUND;
END;
$$;

-- =====================================================
-- 7. DEPRECATE PLAINTEXT COLUMNS (AFTER MIGRATION)
-- =====================================================

-- Add comments to mark plaintext columns as deprecated
COMMENT ON COLUMN creator_profiles.bank_account_number IS
'DEPRECATED: Use bank_account_number_encrypted instead. This column will be removed in a future migration.';

COMMENT ON COLUMN creator_profiles.resident_registration_number IS
'DEPRECATED: Use resident_registration_number_encrypted instead. This column will be removed in a future migration.';

-- Create a scheduled job hint to clear plaintext after verification
-- (Actual job should be created in application layer)
COMMENT ON TABLE creator_profiles IS
'Creator profile data. NOTE: After verifying encrypted migration, run:
ALTER TABLE creator_profiles DROP COLUMN bank_account_number;
ALTER TABLE creator_profiles DROP COLUMN resident_registration_number;';

-- =====================================================
-- 8. AUDIT LOG FOR SENSITIVE DATA ACCESS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.sensitive_data_access_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  accessor_user_id UUID REFERENCES auth.users(id),
  target_user_id UUID REFERENCES auth.users(id),
  data_type TEXT NOT NULL, -- 'bank_account', 'rrn', etc.
  access_type TEXT NOT NULL, -- 'read', 'write'
  ip_address INET,
  user_agent TEXT,
  accessed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sensitive_access_log_accessor
  ON sensitive_data_access_log(accessor_user_id, accessed_at DESC);
CREATE INDEX IF NOT EXISTS idx_sensitive_access_log_target
  ON sensitive_data_access_log(target_user_id, accessed_at DESC);

-- RLS for audit log (admins only)
ALTER TABLE sensitive_data_access_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view audit log"
  ON sensitive_data_access_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Function to log sensitive data access
CREATE OR REPLACE FUNCTION log_sensitive_access(
  p_target_user_id UUID,
  p_data_type TEXT,
  p_access_type TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO sensitive_data_access_log (
    accessor_user_id,
    target_user_id,
    data_type,
    access_type
  )
  VALUES (
    auth.uid(),
    p_target_user_id,
    p_data_type,
    p_access_type
  );
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION encrypt_sensitive TO authenticated;
GRANT EXECUTE ON FUNCTION decrypt_sensitive TO service_role;
GRANT EXECUTE ON FUNCTION mask_sensitive TO authenticated;
GRANT EXECUTE ON FUNCTION get_creator_payout_info TO authenticated;
GRANT EXECUTE ON FUNCTION update_creator_payout_info TO authenticated;
GRANT SELECT ON creator_profiles_masked TO authenticated;
