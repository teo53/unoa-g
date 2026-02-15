-- =====================================================
-- Migration: 059_remove_encryption_key_fallback.sql
-- Purpose: Remove hardcoded development encryption key fallback
-- Security: CRITICAL — prevents production data encrypted with known dev key
--
-- OPS RUNBOOK (반드시 마이그레이션 적용 전 실행):
-- ─────────────────────────────────────────────────
-- 1. 암호화 키 생성 (최소 32바이트):
--      openssl rand -base64 48
--
-- 2. DB GUC로 service_role에만 설정 (노출면 최소화):
--      ALTER ROLE service_role SET app.encryption_key = '<생성된 키>';
--    ※ supabase secrets set은 Edge Function 환경변수이므로
--       DB의 current_setting()과 무관. 반드시 ALTER ROLE 사용.
--    ※ ALTER DATABASE는 모든 세션에 키 노출 → ALTER ROLE이 더 안전
--
-- 3. 적용 확인:
--      SET ROLE service_role;
--      SELECT encrypt_sensitive('test_value');
--      → 정상 암호문 반환되면 성공
--      RESET ROLE;
--
-- 4. 키 미설정 시: encrypt_sensitive()/decrypt_sensitive()가
--    RAISE EXCEPTION → 정산/출금 기능 즉시 장애
--
-- 5. 롤백: 자동 다운 마이그레이션 없음.
--    수동으로 migration 026의 함수 정의를 재적용하거나
--    별도 060_rollback_encryption.sql을 준비할 것.
--
-- search_path 결정: 이 2개 함수는 암호화 키를 다루는 SECURITY DEFINER이므로
-- pg_temp 하이재킹 방지를 위해 pg_catalog, public, pg_temp를 명시.
-- (프로젝트 전체 48+ 함수는 public만 사용 → 별도 일괄 마이그레이션에서 수렴)
-- =====================================================

BEGIN;

-- Replace encrypt_sensitive: fail loudly when key is missing
CREATE OR REPLACE FUNCTION encrypt_sensitive(
  p_plaintext TEXT,
  p_key_id TEXT DEFAULT 'primary_key_v1'
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
  v_key TEXT;
  v_encrypted BYTEA;
BEGIN
  -- Get encryption key from environment
  v_key := current_setting('app.encryption_key', true);

  -- Try key-specific setting as fallback
  IF v_key IS NULL OR v_key = '' THEN
    v_key := current_setting('app.encryption_key_' || p_key_id, true);
  END IF;

  -- CRITICAL: Fail if no key is configured (do NOT fall back to dev key)
  IF v_key IS NULL OR v_key = '' THEN
    RAISE EXCEPTION 'ENCRYPTION_KEY_MISSING: app.encryption_key is not configured. '
      'Set it via ALTER ROLE service_role SET app.encryption_key = ...';
  END IF;

  -- Validate key length (32 bytes minimum for AES-256)
  IF length(v_key) < 32 THEN
    RAISE EXCEPTION 'ENCRYPTION_KEY_TOO_SHORT: key must be at least 32 bytes. Current: %', length(v_key);
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

-- Replace decrypt_sensitive: fail loudly when key is missing
CREATE OR REPLACE FUNCTION decrypt_sensitive(p_encrypted TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
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

  -- Try key-specific setting as fallback
  IF v_key IS NULL OR v_key = '' THEN
    v_key := current_setting('app.encryption_key_' || v_key_id, true);
  END IF;

  -- CRITICAL: Fail if no key is configured (do NOT fall back to dev key)
  IF v_key IS NULL OR v_key = '' THEN
    RAISE EXCEPTION 'ENCRYPTION_KEY_MISSING: app.encryption_key is not configured. '
      'Set it via ALTER ROLE service_role SET app.encryption_key = ...';
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
-- EXECUTE privilege hardening (migration 057 패턴 준수)
-- encrypt/decrypt는 서버 사이드에서만 호출 (Edge Functions via service_role)
-- 클라이언트(authenticated/anon)에서 직접 호출 차단
-- =====================================================
REVOKE EXECUTE ON FUNCTION public.encrypt_sensitive(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.decrypt_sensitive(TEXT) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.encrypt_sensitive(TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.decrypt_sensitive(TEXT) TO service_role;

COMMIT;
