-- =====================================================
-- Migration: 026_security_hardening.sql
-- Purpose: Security hardening - remove hardcoded keys and fix audit log policy
-- Description:
--   1. Remove hardcoded fallback encryption key (CRITICAL)
--   2. Fix overly permissive audit log INSERT policy (HIGH)
--   3. Add secure logging function
-- =====================================================

-- =====================================================
-- 1. FIX ENCRYPTION KEY FALLBACK (CRITICAL)
-- =====================================================

-- Replace encrypt_sensitive function - remove hardcoded key fallback
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
  v_key := current_setting('app.encryption_key', true);

  -- SECURITY FIX: Fail fast if key is not configured
  -- Previous version had a hardcoded fallback - this is now removed
  IF v_key IS NULL OR v_key = '' THEN
    v_key := current_setting('app.encryption_key_' || p_key_id, true);
  END IF;

  IF v_key IS NULL OR v_key = '' THEN
    RAISE EXCEPTION 'SECURITY ERROR: Encryption key not configured. '
      'Set app.encryption_key in your Supabase project settings. '
      'For Supabase: Dashboard > Project Settings > Database > Connection Parameters > app.encryption_key';
  END IF;

  -- Validate key length (32 bytes minimum for AES-256)
  IF length(v_key) < 32 THEN
    RAISE EXCEPTION 'SECURITY ERROR: Encryption key must be at least 32 bytes. Current length: %', length(v_key);
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

-- Replace decrypt_sensitive function - remove hardcoded key fallback
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
    v_key := current_setting('app.encryption_key_' || v_key_id, true);
  END IF;

  -- SECURITY FIX: Fail fast if key is not configured
  IF v_key IS NULL OR v_key = '' THEN
    RAISE WARNING 'Decryption failed: Encryption key not configured for key_id: %', v_key_id;
    RETURN NULL;
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

-- =====================================================
-- 2. FIX AUDIT LOG INSERT POLICY (HIGH)
-- =====================================================

-- Drop the insecure policy
DROP POLICY IF EXISTS "System can insert audit log" ON admin_audit_log;

-- Create secure policy: Only service_role or admins can insert
CREATE POLICY "Secure audit log insert"
  ON admin_audit_log FOR INSERT
  WITH CHECK (
    -- Service role can always insert (backend operations via Edge Functions)
    (current_setting('request.jwt.claims', true)::jsonb->>'role') = 'service_role'
    OR
    -- Authenticated admins can insert via the secure function
    public.is_admin()
  );

-- =====================================================
-- 3. CREATE SECURE LOGGING FUNCTION
-- =====================================================

-- Replace the existing log_admin_action with a more secure version
CREATE OR REPLACE FUNCTION public.log_admin_action(
  p_action TEXT,
  p_table_name TEXT,
  p_record_id UUID DEFAULT NULL,
  p_old_data JSONB DEFAULT NULL,
  p_new_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_log_id UUID;
  v_user_id UUID;
  v_is_service_role BOOLEAN;
BEGIN
  -- Get the current user
  v_user_id := auth.uid();
  v_is_service_role := (current_setting('request.jwt.claims', true)::jsonb->>'role') = 'service_role';

  -- Validate: Must be service_role or authenticated admin
  IF NOT v_is_service_role THEN
    IF v_user_id IS NULL THEN
      RAISE EXCEPTION 'Unauthorized: Must be authenticated to log admin actions';
    END IF;

    IF NOT public.is_admin(v_user_id) THEN
      RAISE EXCEPTION 'Unauthorized: Only admins can log admin actions. User: %', v_user_id;
    END IF;
  END IF;

  -- Insert the audit log entry
  INSERT INTO admin_audit_log (
    admin_user_id,
    action,
    table_name,
    record_id,
    old_data,
    new_data
  )
  VALUES (
    COALESCE(v_user_id, '00000000-0000-0000-0000-000000000000'::UUID), -- System user for service_role
    p_action,
    p_table_name,
    p_record_id,
    p_old_data,
    p_new_data
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

-- =====================================================
-- 4. ADD COMMENT FOR DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION encrypt_sensitive IS
'Encrypts sensitive data using AES-256.
CRITICAL: Requires app.encryption_key to be set in Supabase project settings.
The function will FAIL if the key is not configured - this is intentional for security.
To set the key: Dashboard > Project Settings > Database > Connection Parameters';

COMMENT ON FUNCTION decrypt_sensitive IS
'Decrypts data encrypted by encrypt_sensitive.
Returns NULL if decryption fails or key is not configured.
Supports key rotation via key_id prefix in encrypted data.';

COMMENT ON POLICY "Secure audit log insert" ON admin_audit_log IS
'Only service_role or authenticated admins can insert audit log entries.
This prevents unauthorized users from polluting the audit trail.';

-- =====================================================
-- 5. VERIFY MIGRATION
-- =====================================================

DO $$
BEGIN
  -- Verify the new policies exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'admin_audit_log'
    AND policyname = 'Secure audit log insert'
  ) THEN
    RAISE EXCEPTION 'Migration failed: Secure audit log insert policy not created';
  END IF;

  RAISE NOTICE 'Security hardening migration completed successfully';
  RAISE NOTICE 'IMPORTANT: Ensure app.encryption_key is set in production before using encryption functions';
END $$;
