-- ============================================================
-- Migration 082: fan_ads ops atomic RPCs
-- ============================================================
-- approve_fan_ad_atomic:
--   fan_ads lock -> ops_banners(published) insert ->
--   fan_ads status/ops_banner_id update -> audit -> refresh config
--
-- reject_fan_ad_atomic:
--   fan_ads lock -> status/reason update -> audit
-- ============================================================

-- ────────────────────────────────────────────────
-- F1. approve_fan_ad_atomic
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.approve_fan_ad_atomic(
  p_fan_ad_id   UUID,
  p_placement   TEXT,
  p_priority    INT DEFAULT 0,
  p_actor_id    UUID,
  p_actor_role  TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_fan_ad        fan_ads;
  v_ops_banner_id UUID;
  v_before        JSONB;
  v_after         JSONB;
BEGIN
  IF p_placement NOT IN (
    'home_top', 'home_bottom', 'discover_top', 'chat_top',
    'chat_list', 'profile_banner', 'funding_top', 'popup'
  ) THEN
    RAISE EXCEPTION 'invalid_placement: %', p_placement;
  END IF;

  -- 1) Lock fan_ad row
  SELECT * INTO v_fan_ad
  FROM fan_ads
  WHERE id = p_fan_ad_id
  FOR UPDATE;

  IF v_fan_ad IS NULL THEN
    RAISE EXCEPTION 'fan_ad_not_found: %', p_fan_ad_id;
  END IF;

  -- 2) Validate transition
  IF v_fan_ad.status <> 'pending_review' THEN
    RAISE EXCEPTION 'invalid_status: % cannot transition to approved', v_fan_ad.status;
  END IF;

  -- 3) Create published ops banner linked to fan_ad
  INSERT INTO ops_banners (
    title,
    placement,
    image_url,
    link_url,
    link_type,
    status,
    priority,
    start_at,
    end_at,
    target_audience,
    version,
    created_by,
    updated_by,
    source_type,
    fan_ad_id
  )
  VALUES (
    v_fan_ad.title,
    p_placement,
    COALESCE(v_fan_ad.image_url, ''),
    COALESCE(v_fan_ad.link_url, ''),
    COALESCE(v_fan_ad.link_type, 'none'),
    'published',
    COALESCE(p_priority, 0),
    v_fan_ad.start_at,
    v_fan_ad.end_at,
    'all',
    1,
    p_actor_id,
    p_actor_id,
    'fan_ad',
    v_fan_ad.id
  )
  RETURNING id INTO v_ops_banner_id;

  -- 4) Update fan_ad link + status
  UPDATE fan_ads
  SET
    status = 'approved',
    rejection_reason = NULL,
    ops_banner_id = v_ops_banner_id,
    updated_at = now()
  WHERE id = v_fan_ad.id;

  -- 5) Audit log
  v_before := jsonb_build_object(
    'status', v_fan_ad.status,
    'ops_banner_id', v_fan_ad.ops_banner_id
  );
  v_after := jsonb_build_object(
    'status', 'approved',
    'ops_banner_id', v_ops_banner_id
  );

  INSERT INTO ops_audit_log (
    actor_id, actor_role, action, entity_type, entity_id,
    before, after, metadata
  ) VALUES (
    p_actor_id, p_actor_role, 'fan_ad.approve', 'fan_ads', v_fan_ad.id,
    v_before, v_after,
    jsonb_build_object(
      'placement', p_placement,
      'priority', COALESCE(p_priority, 0),
      'ops_banner_id', v_ops_banner_id
    )
  );

  -- 6) Refresh app config (banner already published)
  PERFORM refresh_app_public_config();

  RETURN jsonb_build_object(
    'fan_ad_id', v_fan_ad.id,
    'ops_banner_id', v_ops_banner_id,
    'status', 'approved'
  );
END;
$$;

COMMENT ON FUNCTION public.approve_fan_ad_atomic IS
  'Atomically approve fan ad and publish linked ops banner.';

-- ────────────────────────────────────────────────
-- F2. reject_fan_ad_atomic
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.reject_fan_ad_atomic(
  p_fan_ad_id         UUID,
  p_rejection_reason  TEXT,
  p_actor_id          UUID,
  p_actor_role        TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_fan_ad   fan_ads;
  v_reason   TEXT;
  v_before   JSONB;
  v_after    JSONB;
BEGIN
  v_reason := btrim(COALESCE(p_rejection_reason, ''));
  IF char_length(v_reason) = 0 THEN
    RAISE EXCEPTION 'invalid_rejection_reason: required';
  END IF;
  IF char_length(v_reason) > 500 THEN
    RAISE EXCEPTION 'invalid_rejection_reason: too_long';
  END IF;

  -- 1) Lock fan_ad row
  SELECT * INTO v_fan_ad
  FROM fan_ads
  WHERE id = p_fan_ad_id
  FOR UPDATE;

  IF v_fan_ad IS NULL THEN
    RAISE EXCEPTION 'fan_ad_not_found: %', p_fan_ad_id;
  END IF;

  -- 2) Validate transition
  IF v_fan_ad.status <> 'pending_review' THEN
    RAISE EXCEPTION 'invalid_status: % cannot transition to rejected', v_fan_ad.status;
  END IF;

  -- 3) Reject
  UPDATE fan_ads
  SET
    status = 'rejected',
    rejection_reason = v_reason,
    updated_at = now()
  WHERE id = v_fan_ad.id;

  -- 4) Audit
  v_before := jsonb_build_object('status', v_fan_ad.status);
  v_after := jsonb_build_object('status', 'rejected', 'rejection_reason', v_reason);

  INSERT INTO ops_audit_log (
    actor_id, actor_role, action, entity_type, entity_id,
    before, after, metadata
  ) VALUES (
    p_actor_id, p_actor_role, 'fan_ad.reject', 'fan_ads', v_fan_ad.id,
    v_before, v_after, jsonb_build_object()
  );

  RETURN jsonb_build_object(
    'fan_ad_id', v_fan_ad.id,
    'status', 'rejected'
  );
END;
$$;

COMMENT ON FUNCTION public.reject_fan_ad_atomic IS
  'Atomically reject fan ad with rejection reason and audit logging.';

-- ────────────────────────────────────────────────
-- Grants (Edge Function via service_role only)
-- ────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.approve_fan_ad_atomic(UUID, TEXT, INT, UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.reject_fan_ad_atomic(UUID, TEXT, UUID, TEXT) TO service_role;

REVOKE EXECUTE ON FUNCTION public.approve_fan_ad_atomic(UUID, TEXT, INT, UUID, TEXT) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.reject_fan_ad_atomic(UUID, TEXT, UUID, TEXT) FROM authenticated;
