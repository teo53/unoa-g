-- ============================================================
-- 057: Ops Atomic Publish / Rollback / Archive RPCs
-- ============================================================
-- Ensures banner & flag publish operations are fully atomic:
--   status update + audit log + public config refresh
-- all within a single PL/pgSQL transaction.
--
-- Pattern: Follows process_payment_atomic() (010) and
--          mark_funding_payment_refunded() (045).
-- ============================================================

-- ────────────────────────────────────────────────
-- Helper: Internal audit log (accepts explicit actor)
-- ────────────────────────────────────────────────
-- Unlike log_ops_audit() which uses auth.uid(), these RPCs are
-- called via service_role (no auth context). We insert directly.
-- ────────────────────────────────────────────────

-- ────────────────────────────────────────────────
-- F1. publish_banner_atomic
-- ────────────────────────────────────────────────
-- Atomically: lock → validate version → update status →
--             save snapshot → audit log → refresh config
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.publish_banner_atomic(
  p_banner_id       UUID,
  p_expected_version INT,
  p_actor_id        UUID,
  p_actor_role      TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_banner  ops_banners;
  v_snapshot JSONB;
  v_before  JSONB;
  v_after   JSONB;
BEGIN
  -- 1. Lock the banner row (prevents concurrent publish)
  SELECT * INTO v_banner
  FROM ops_banners
  WHERE id = p_banner_id
  FOR UPDATE;

  IF v_banner IS NULL THEN
    RAISE EXCEPTION 'banner_not_found: %', p_banner_id;
  END IF;

  -- 2. Optimistic locking: version must match
  IF v_banner.version <> p_expected_version THEN
    RAISE EXCEPTION 'version_conflict: expected=% actual=%',
      p_expected_version, v_banner.version;
  END IF;

  -- 3. Validate state transition: only draft/in_review → published
  IF v_banner.status NOT IN ('draft', 'in_review') THEN
    RAISE EXCEPTION 'invalid_status: % cannot transition to published',
      v_banner.status;
  END IF;

  -- 4. Build published snapshot (frozen copy for rollback)
  v_snapshot := jsonb_build_object(
    'id', v_banner.id,
    'title', v_banner.title,
    'placement', v_banner.placement,
    'image_url', v_banner.image_url,
    'link_url', v_banner.link_url,
    'link_type', v_banner.link_type,
    'priority', v_banner.priority,
    'start_at', v_banner.start_at,
    'end_at', v_banner.end_at,
    'target_audience', v_banner.target_audience
  );

  -- 5. Update banner status + snapshot + version
  UPDATE ops_banners SET
    status = 'published',
    version = v_banner.version + 1,
    published_snapshot = v_snapshot,
    updated_by = p_actor_id,
    updated_at = now()
  WHERE id = p_banner_id;

  -- 6. Diff-only audit log (before/after changed fields)
  v_before := jsonb_build_object('status', v_banner.status);
  v_after  := jsonb_build_object('status', 'published');

  INSERT INTO ops_audit_log (
    actor_id, actor_role, action, entity_type, entity_id,
    before, after, metadata
  ) VALUES (
    p_actor_id, p_actor_role, 'banner.publish', 'ops_banners', p_banner_id,
    v_before, v_after,
    jsonb_build_object('version_before', v_banner.version, 'version_after', v_banner.version + 1)
  );

  -- 7. Refresh public config (atomic with everything above)
  PERFORM refresh_app_public_config();

  -- 8. Return success payload
  RETURN jsonb_build_object(
    'success', true,
    'id', p_banner_id,
    'status', 'published',
    'version', v_banner.version + 1,
    'published_snapshot', v_snapshot
  );
END;
$$;

COMMENT ON FUNCTION public.publish_banner_atomic IS
  'Atomically publish a banner: lock + version check + status update + audit + config refresh.';

-- ────────────────────────────────────────────────
-- F2. publish_flag_atomic
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.publish_flag_atomic(
  p_flag_id          UUID,
  p_expected_version INT,
  p_actor_id         UUID,
  p_actor_role       TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_flag    ops_feature_flags;
  v_snapshot JSONB;
  v_before  JSONB;
  v_after   JSONB;
BEGIN
  -- 1. Lock the flag row
  SELECT * INTO v_flag
  FROM ops_feature_flags
  WHERE id = p_flag_id
  FOR UPDATE;

  IF v_flag IS NULL THEN
    RAISE EXCEPTION 'flag_not_found: %', p_flag_id;
  END IF;

  -- 2. Optimistic locking
  IF v_flag.version <> p_expected_version THEN
    RAISE EXCEPTION 'version_conflict: expected=% actual=%',
      p_expected_version, v_flag.version;
  END IF;

  -- 3. Validate state: only draft → published
  IF v_flag.status <> 'draft' THEN
    RAISE EXCEPTION 'invalid_status: % cannot transition to published',
      v_flag.status;
  END IF;

  -- 4. Build published snapshot
  v_snapshot := jsonb_build_object(
    'id', v_flag.id,
    'flag_key', v_flag.flag_key,
    'title', v_flag.title,
    'enabled', v_flag.enabled,
    'rollout_percent', v_flag.rollout_percent,
    'payload', v_flag.payload
  );

  -- 5. Update flag status + snapshot + version
  UPDATE ops_feature_flags SET
    status = 'published',
    version = v_flag.version + 1,
    published_snapshot = v_snapshot,
    updated_by = p_actor_id,
    updated_at = now()
  WHERE id = p_flag_id;

  -- 6. Audit log
  v_before := jsonb_build_object('status', v_flag.status);
  v_after  := jsonb_build_object('status', 'published');

  INSERT INTO ops_audit_log (
    actor_id, actor_role, action, entity_type, entity_id,
    before, after, metadata
  ) VALUES (
    p_actor_id, p_actor_role, 'flag.publish', 'ops_feature_flags', p_flag_id,
    v_before, v_after,
    jsonb_build_object('version_before', v_flag.version, 'version_after', v_flag.version + 1)
  );

  -- 7. Refresh public config
  PERFORM refresh_app_public_config();

  -- 8. Return success
  RETURN jsonb_build_object(
    'success', true,
    'id', p_flag_id,
    'flag_key', v_flag.flag_key,
    'status', 'published',
    'version', v_flag.version + 1,
    'published_snapshot', v_snapshot
  );
END;
$$;

COMMENT ON FUNCTION public.publish_flag_atomic IS
  'Atomically publish a feature flag: lock + version check + status update + audit + config refresh.';

-- ────────────────────────────────────────────────
-- F3. rollback_banner_atomic
-- ────────────────────────────────────────────────
-- Restores banner from published_snapshot, sets status back to draft.
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.rollback_banner_atomic(
  p_banner_id  UUID,
  p_actor_id   UUID,
  p_actor_role TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_banner   ops_banners;
  v_snapshot  JSONB;
  v_before   JSONB;
  v_after    JSONB;
BEGIN
  -- 1. Lock the banner row
  SELECT * INTO v_banner
  FROM ops_banners
  WHERE id = p_banner_id
  FOR UPDATE;

  IF v_banner IS NULL THEN
    RAISE EXCEPTION 'banner_not_found: %', p_banner_id;
  END IF;

  -- 2. Validate: only published banners can be rolled back
  IF v_banner.status <> 'published' THEN
    RAISE EXCEPTION 'invalid_status: % cannot rollback (not published)',
      v_banner.status;
  END IF;

  -- 3. Ensure snapshot exists for rollback
  v_snapshot := v_banner.published_snapshot;
  IF v_snapshot IS NULL THEN
    RAISE EXCEPTION 'no_snapshot: banner % has no published_snapshot to rollback to',
      p_banner_id;
  END IF;

  -- 4. Restore banner from snapshot + set status to draft
  UPDATE ops_banners SET
    status = 'draft',
    title = COALESCE(v_snapshot->>'title', v_banner.title),
    placement = COALESCE(v_snapshot->>'placement', v_banner.placement),
    image_url = COALESCE(v_snapshot->>'image_url', v_banner.image_url),
    link_url = COALESCE(v_snapshot->>'link_url', v_banner.link_url),
    link_type = COALESCE(v_snapshot->>'link_type', v_banner.link_type),
    priority = COALESCE((v_snapshot->>'priority')::INT, v_banner.priority),
    target_audience = COALESCE(v_snapshot->>'target_audience', v_banner.target_audience),
    version = v_banner.version + 1,
    published_snapshot = NULL,  -- Clear snapshot after rollback
    updated_by = p_actor_id,
    updated_at = now()
  WHERE id = p_banner_id;

  -- 5. Audit log
  v_before := jsonb_build_object('status', 'published');
  v_after  := jsonb_build_object('status', 'draft', 'rollback_from_snapshot', true);

  INSERT INTO ops_audit_log (
    actor_id, actor_role, action, entity_type, entity_id,
    before, after, metadata
  ) VALUES (
    p_actor_id, p_actor_role, 'banner.rollback', 'ops_banners', p_banner_id,
    v_before, v_after,
    jsonb_build_object('version_before', v_banner.version, 'version_after', v_banner.version + 1)
  );

  -- 6. Refresh public config (removes banner from published set)
  PERFORM refresh_app_public_config();

  -- 7. Return success
  RETURN jsonb_build_object(
    'success', true,
    'id', p_banner_id,
    'status', 'draft',
    'version', v_banner.version + 1,
    'rolled_back_from_snapshot', true
  );
END;
$$;

COMMENT ON FUNCTION public.rollback_banner_atomic IS
  'Atomically rollback a published banner to draft state, restoring from snapshot.';

-- ────────────────────────────────────────────────
-- F4. rollback_flag_atomic
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.rollback_flag_atomic(
  p_flag_id    UUID,
  p_actor_id   UUID,
  p_actor_role TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_flag     ops_feature_flags;
  v_snapshot  JSONB;
  v_before   JSONB;
  v_after    JSONB;
BEGIN
  -- 1. Lock the flag row
  SELECT * INTO v_flag
  FROM ops_feature_flags
  WHERE id = p_flag_id
  FOR UPDATE;

  IF v_flag IS NULL THEN
    RAISE EXCEPTION 'flag_not_found: %', p_flag_id;
  END IF;

  -- 2. Validate: only published flags can be rolled back
  IF v_flag.status <> 'published' THEN
    RAISE EXCEPTION 'invalid_status: % cannot rollback (not published)',
      v_flag.status;
  END IF;

  -- 3. Ensure snapshot exists
  v_snapshot := v_flag.published_snapshot;
  IF v_snapshot IS NULL THEN
    RAISE EXCEPTION 'no_snapshot: flag % has no published_snapshot to rollback to',
      p_flag_id;
  END IF;

  -- 4. Restore flag from snapshot + set status to draft
  UPDATE ops_feature_flags SET
    status = 'draft',
    enabled = COALESCE((v_snapshot->>'enabled')::BOOLEAN, v_flag.enabled),
    rollout_percent = COALESCE((v_snapshot->>'rollout_percent')::INT, v_flag.rollout_percent),
    payload = COALESCE(v_snapshot->'payload', v_flag.payload),
    version = v_flag.version + 1,
    published_snapshot = NULL,
    updated_by = p_actor_id,
    updated_at = now()
  WHERE id = p_flag_id;

  -- 5. Audit log
  v_before := jsonb_build_object('status', 'published');
  v_after  := jsonb_build_object('status', 'draft', 'rollback_from_snapshot', true);

  INSERT INTO ops_audit_log (
    actor_id, actor_role, action, entity_type, entity_id,
    before, after, metadata
  ) VALUES (
    p_actor_id, p_actor_role, 'flag.rollback', 'ops_feature_flags', p_flag_id,
    v_before, v_after,
    jsonb_build_object('version_before', v_flag.version, 'version_after', v_flag.version + 1)
  );

  -- 6. Refresh public config (removes flag from published set)
  PERFORM refresh_app_public_config();

  -- 7. Return success
  RETURN jsonb_build_object(
    'success', true,
    'id', p_flag_id,
    'flag_key', v_flag.flag_key,
    'status', 'draft',
    'version', v_flag.version + 1,
    'rolled_back_from_snapshot', true
  );
END;
$$;

COMMENT ON FUNCTION public.rollback_flag_atomic IS
  'Atomically rollback a published feature flag to draft state, restoring from snapshot.';

-- ────────────────────────────────────────────────
-- F5. archive_banner_atomic
-- ────────────────────────────────────────────────
-- Archives a banner (any status → archived).
-- If previously published, also refreshes config.
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.archive_banner_atomic(
  p_banner_id  UUID,
  p_actor_id   UUID,
  p_actor_role TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_banner      ops_banners;
  v_was_published BOOLEAN;
  v_before      JSONB;
  v_after       JSONB;
BEGIN
  -- 1. Lock the banner row
  SELECT * INTO v_banner
  FROM ops_banners
  WHERE id = p_banner_id
  FOR UPDATE;

  IF v_banner IS NULL THEN
    RAISE EXCEPTION 'banner_not_found: %', p_banner_id;
  END IF;

  -- 2. Validate: cannot archive an already archived banner
  IF v_banner.status = 'archived' THEN
    RAISE EXCEPTION 'invalid_status: banner is already archived';
  END IF;

  -- 3. Track if was published (need to refresh config)
  v_was_published := (v_banner.status = 'published');

  -- 4. Update status to archived
  UPDATE ops_banners SET
    status = 'archived',
    version = v_banner.version + 1,
    updated_by = p_actor_id,
    updated_at = now()
  WHERE id = p_banner_id;

  -- 5. Audit log
  v_before := jsonb_build_object('status', v_banner.status);
  v_after  := jsonb_build_object('status', 'archived');

  INSERT INTO ops_audit_log (
    actor_id, actor_role, action, entity_type, entity_id,
    before, after, metadata
  ) VALUES (
    p_actor_id, p_actor_role, 'banner.archive', 'ops_banners', p_banner_id,
    v_before, v_after,
    jsonb_build_object(
      'version_before', v_banner.version,
      'version_after', v_banner.version + 1,
      'was_published', v_was_published
    )
  );

  -- 6. Refresh public config only if was published (removes from live)
  IF v_was_published THEN
    PERFORM refresh_app_public_config();
  END IF;

  -- 7. Return success
  RETURN jsonb_build_object(
    'success', true,
    'id', p_banner_id,
    'status', 'archived',
    'version', v_banner.version + 1,
    'was_published', v_was_published
  );
END;
$$;

COMMENT ON FUNCTION public.archive_banner_atomic IS
  'Atomically archive a banner. If was published, also refreshes public config.';

-- ============================================================
-- GRANTS: service_role only (called via Edge Function)
-- ============================================================
GRANT EXECUTE ON FUNCTION public.publish_banner_atomic(UUID, INT, UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.publish_flag_atomic(UUID, INT, UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rollback_banner_atomic(UUID, UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rollback_flag_atomic(UUID, UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.archive_banner_atomic(UUID, UUID, TEXT) TO service_role;

-- Revoke from authenticated (only callable via Edge Function)
REVOKE EXECUTE ON FUNCTION public.publish_banner_atomic(UUID, INT, UUID, TEXT) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.publish_flag_atomic(UUID, INT, UUID, TEXT) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.rollback_banner_atomic(UUID, UUID, TEXT) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.rollback_flag_atomic(UUID, UUID, TEXT) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.archive_banner_atomic(UUID, UUID, TEXT) FROM authenticated;
