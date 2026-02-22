-- ============================================================
-- Migration: 104_encryption_key_fail_closed.sql
-- Purpose: P0-5 — Remove dev-key fallback from encrypt/decrypt functions
--
-- Problem:
--   encrypt_sensitive() and decrypt_sensitive() fall back to a hardcoded
--   development key ('DEVELOPMENT_KEY_DO_NOT_USE_IN_PRODUCTION_32B!')
--   when app.encryption_key is not set. If the key is ever misconfigured
--   or absent in production, sensitive data (bank accounts, RRN) gets
--   encrypted with a publicly-known key.
--
-- Fix:
--   FAIL-CLOSED — raise an exception if app.encryption_key is not set.
--   Development environments must explicitly set the key even locally.
--
-- Approach: CREATE OR REPLACE (idempotent).
-- ============================================================

BEGIN;

-- ============================================================
-- 1. Replace encrypt_sensitive — fail-closed on missing key
-- ============================================================
CREATE OR REPLACE FUNCTION encrypt_sensitive(
  p_plaintext TEXT,
  p_key_id TEXT DEFAULT 'primary_key_v1'
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_key TEXT;
  v_encrypted BYTEA;
BEGIN
  -- Return NULL for NULL input
  IF p_plaintext IS NULL THEN
    RETURN NULL;
  END IF;

  -- Get encryption key from environment
  v_key := current_setting('app.encryption_key', true);

  -- FAIL-CLOSED: reject if key is missing or empty
  IF v_key IS NULL OR v_key = '' THEN
    RAISE EXCEPTION 'SECURITY FAIL-CLOSED: app.encryption_key is not configured. '
      'Set via: ALTER DATABASE current SET app.encryption_key = ''your-32-byte-key''; '
      'or per-session: SET app.encryption_key = ''...'';';
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

-- ============================================================
-- 2. Replace decrypt_sensitive — fail-closed on missing key
-- ============================================================
CREATE OR REPLACE FUNCTION decrypt_sensitive(p_encrypted TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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

  -- FAIL-CLOSED: reject if key is missing or empty
  IF v_key IS NULL OR v_key = '' THEN
    RAISE EXCEPTION 'SECURITY FAIL-CLOSED: app.encryption_key is not configured. '
      'Cannot decrypt sensitive data without the encryption key.';
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

-- ============================================================
-- 3. Verification block
-- ============================================================
DO $$
DECLARE
  v_func_body TEXT;
BEGIN
  -- Verify encrypt_sensitive no longer contains the dev fallback key
  SELECT prosrc INTO v_func_body
  FROM pg_proc
  WHERE proname = 'encrypt_sensitive'
  ORDER BY oid DESC LIMIT 1;

  IF v_func_body LIKE '%DEVELOPMENT_KEY_DO_NOT_USE%' THEN
    RAISE EXCEPTION 'Migration failed: encrypt_sensitive still contains dev fallback key';
  END IF;

  -- Verify decrypt_sensitive no longer contains the dev fallback key
  SELECT prosrc INTO v_func_body
  FROM pg_proc
  WHERE proname = 'decrypt_sensitive'
  ORDER BY oid DESC LIMIT 1;

  IF v_func_body LIKE '%DEVELOPMENT_KEY_DO_NOT_USE%' THEN
    RAISE EXCEPTION 'Migration failed: decrypt_sensitive still contains dev fallback key';
  END IF;

  RAISE NOTICE '104_encryption_key_fail_closed: P0-5 fix applied — dev key fallback removed';
END $$;

COMMIT;
