-- ============================================================
-- 077: Add auth.uid() Ownership Checks to User-Facing RPCs
-- ============================================================
-- P0-5: Consent RPCs allow cross-user read/modify (no auth check)
-- P0-6: track_storage_usage allows cross-user record injection
-- P0-3 supplement: get_expiring_dt_summary leaks other users' data
--
-- Fix: CREATE OR REPLACE with auth.uid() = p_user_id guard at top.
-- Signatures are identical → existing GRANTs preserved.
-- ============================================================

BEGIN;

-- ============================================================
-- P0-5a: get_user_consent_summary — read-only but leaks privacy
-- Original: 018_user_consents_enhancement.sql
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_user_consent_summary(p_user_id UUID)
RETURNS TABLE (
  consent_type consent_type,
  version VARCHAR(20),
  agreed BOOLEAN,
  agreed_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  is_required BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- P0-5 fix: only allow querying own consent data
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'access_denied';
  END IF;

  RETURN QUERY
  SELECT
    uc.consent_type,
    uc.version,
    uc.agreed,
    uc.agreed_at,
    uc.revoked_at,
    cd.is_required
  FROM user_consents uc
  LEFT JOIN consent_documents cd
    ON cd.consent_type = uc.consent_type AND cd.version = uc.version
  WHERE uc.user_id = p_user_id
  ORDER BY cd.is_required DESC, uc.consent_type;
END;
$$;

-- ============================================================
-- P0-5b: revoke_marketing_consent — cross-user consent revocation
-- Original: 018_user_consents_enhancement.sql
-- ============================================================

CREATE OR REPLACE FUNCTION public.revoke_marketing_consent(
  p_user_id UUID,
  p_consent_type consent_type,
  p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- P0-5 fix: only allow revoking own consent
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'access_denied';
  END IF;

  UPDATE user_consents
  SET
    agreed = false,
    revoked_at = NOW(),
    revocation_reason = p_reason,
    updated_at = NOW()
  WHERE user_id = p_user_id
    AND consent_type = p_consent_type
    AND agreed = true;

  RETURN FOUND;
END;
$$;

-- ============================================================
-- P0-5c: revoke_all_marketing_consents — cross-user bulk revocation
-- Original: 018_user_consents_enhancement.sql
-- ============================================================

CREATE OR REPLACE FUNCTION public.revoke_all_marketing_consents(
  p_user_id UUID,
  p_reason TEXT DEFAULT 'User requested opt-out'
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  revoked_count INT;
BEGIN
  -- P0-5 fix: only allow revoking own consent
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'access_denied';
  END IF;

  UPDATE user_consents
  SET
    agreed = false,
    revoked_at = NOW(),
    revocation_reason = p_reason,
    updated_at = NOW()
  WHERE user_id = p_user_id
    AND consent_type IN ('marketing_email', 'marketing_push', 'marketing_sms')
    AND agreed = true;

  GET DIAGNOSTICS revoked_count = ROW_COUNT;
  RETURN revoked_count;
END;
$$;

-- Revoke from PUBLIC/anon (keep authenticated)
REVOKE EXECUTE ON FUNCTION public.get_user_consent_summary(UUID) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.revoke_marketing_consent(UUID, consent_type, TEXT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.revoke_all_marketing_consents(UUID, TEXT) FROM PUBLIC, anon;

-- ============================================================
-- P0-6: track_storage_usage — cross-user storage record injection
-- Original: 022_funding_storage.sql
-- ============================================================

CREATE OR REPLACE FUNCTION public.track_storage_usage(
  p_user_id UUID,
  p_bucket_name TEXT,
  p_file_path TEXT,
  p_file_size BIGINT,
  p_mime_type TEXT DEFAULT NULL,
  p_campaign_id UUID DEFAULT NULL
)
RETURNS storage_usage
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_record storage_usage;
BEGIN
  -- P0-6 fix: only allow tracking own storage usage
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'access_denied';
  END IF;

  INSERT INTO storage_usage (
    user_id, bucket_name, file_path, file_size, mime_type, campaign_id
  ) VALUES (
    p_user_id, p_bucket_name, p_file_path, p_file_size, p_mime_type, p_campaign_id
  )
  ON CONFLICT (bucket_name, file_path) DO UPDATE SET
    file_size = EXCLUDED.file_size,
    campaign_id = COALESCE(EXCLUDED.campaign_id, storage_usage.campaign_id)
  RETURNING * INTO v_record;

  RETURN v_record;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.track_storage_usage(UUID, TEXT, TEXT, BIGINT, TEXT, UUID) FROM PUBLIC, anon;

-- ============================================================
-- P0-3 supplement: get_expiring_dt_summary — cross-user DT data leak
-- Original: 039_dt_expiration.sql
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_expiring_dt_summary(
  p_user_id UUID,
  p_within_days INT DEFAULT 90
)
RETURNS TABLE (
  purchase_id UUID,
  remaining_dt INT,
  expires_at TIMESTAMPTZ,
  days_until_expiry INT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- P0-3 supplement: only allow querying own DT expiry data
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'access_denied';
  END IF;

  RETURN QUERY
  SELECT
    dp.id as purchase_id,
    (dp.dt_amount + COALESCE(dp.bonus_dt, 0) - COALESCE(dp.dt_used, 0)) as remaining_dt,
    dp.expires_at,
    EXTRACT(DAY FROM dp.expires_at - now())::INT as days_until_expiry
  FROM dt_purchases dp
  WHERE dp.user_id = p_user_id
    AND dp.status = 'paid'
    AND dp.expires_at IS NOT NULL
    AND dp.expires_at <= now() + (p_within_days || ' days')::INTERVAL
    AND (dp.dt_amount + COALESCE(dp.bonus_dt, 0) - COALESCE(dp.dt_used, 0)) > 0
  ORDER BY dp.expires_at ASC;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_expiring_dt_summary(UUID, INT) FROM PUBLIC, anon;

COMMIT;
