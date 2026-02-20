-- ============================================================
-- Migration 085: fan_ads security hardening
-- ============================================================
-- 1) approve_fan_ad_atomic: payment_status='paid' 선검증
-- 2) fan_ads_ops_update 정책 제거 (ops 직접 UPDATE 우회 차단)
-- 3) cancel_fan_ad_atomic 추가 (팬 취소는 RPC-only 경로)
-- ============================================================

-- ------------------------------------------------------------
-- 1) ops 직접 UPDATE 우회 차단
-- ------------------------------------------------------------
DROP POLICY IF EXISTS fan_ads_ops_update ON public.fan_ads;

-- ------------------------------------------------------------
-- 2) approve_fan_ad_atomic 보안 강화
-- ------------------------------------------------------------
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

  -- 2-1) 결제 완료 광고만 승인 가능
  IF v_fan_ad.payment_status <> 'paid' THEN
    RAISE EXCEPTION 'payment_not_paid: %', v_fan_ad.payment_status;
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
    'ops_banner_id', v_fan_ad.ops_banner_id,
    'payment_status', v_fan_ad.payment_status
  );
  v_after := jsonb_build_object(
    'status', 'approved',
    'ops_banner_id', v_ops_banner_id,
    'payment_status', v_fan_ad.payment_status
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
  'Atomically approve fan ad and publish linked ops banner. Requires payment_status=paid.';

GRANT EXECUTE ON FUNCTION public.approve_fan_ad_atomic(UUID, TEXT, INT, UUID, TEXT) TO service_role;
REVOKE EXECUTE ON FUNCTION public.approve_fan_ad_atomic(UUID, TEXT, INT, UUID, TEXT) FROM authenticated;

-- ------------------------------------------------------------
-- 3) cancel_fan_ad_atomic 신규 추가
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_fan_ad_atomic(
  p_fan_ad_id UUID,
  p_actor_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_fan_ad fan_ads;
BEGIN
  IF auth.uid() IS NULL OR auth.uid() <> p_actor_id THEN
    RAISE EXCEPTION 'unauthorized_actor';
  END IF;

  SELECT * INTO v_fan_ad
  FROM fan_ads
  WHERE id = p_fan_ad_id
  FOR UPDATE;

  IF v_fan_ad IS NULL THEN
    RAISE EXCEPTION 'fan_ad_not_found: %', p_fan_ad_id;
  END IF;

  IF v_fan_ad.fan_user_id <> p_actor_id THEN
    RAISE EXCEPTION 'forbidden_actor';
  END IF;

  IF v_fan_ad.status <> 'pending_review' THEN
    RAISE EXCEPTION 'invalid_status: % cannot transition to cancelled', v_fan_ad.status;
  END IF;

  UPDATE fan_ads
  SET
    status = 'cancelled',
    updated_at = now()
  WHERE id = v_fan_ad.id;

  RETURN jsonb_build_object(
    'fan_ad_id', v_fan_ad.id,
    'status', 'cancelled'
  );
END;
$$;

COMMENT ON FUNCTION public.cancel_fan_ad_atomic IS
  'Atomically cancel fan ad by owner while status is pending_review.';

-- 권한: cancel RPC는 앱(authenticated) + 서비스롤에서 호출 가능
REVOKE ALL ON FUNCTION public.cancel_fan_ad_atomic(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_fan_ad_atomic(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_fan_ad_atomic(UUID, UUID) TO service_role;
