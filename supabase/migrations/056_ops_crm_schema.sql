-- ============================================================
-- 056: Ops CRM Schema — RBAC, Banners, Feature Flags, Audit
-- ============================================================
-- Phase 1 MVP for non-developer operations management.
-- Extends existing admin infrastructure (admin_users, is_admin).
-- ============================================================

-- ────────────────────────────────────────────────
-- 1. ops_staff — RBAC for operations team
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ops_staff (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL DEFAULT 'viewer'
              CHECK (role IN ('viewer', 'operator', 'publisher', 'admin')),
  display_name TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id)
);

ALTER TABLE public.ops_staff ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.ops_staff IS
  'Operations team members with RBAC roles: viewer < operator < publisher < admin';

-- ────────────────────────────────────────────────
-- 2. ops_assets — Image / media library
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ops_assets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_name   TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  public_url  TEXT NOT NULL,
  mime_type   TEXT NOT NULL,
  file_size   BIGINT NOT NULL DEFAULT 0,
  width       INT,
  height      INT,
  tags        TEXT[] DEFAULT '{}',
  alt_text    TEXT DEFAULT '',
  uploaded_by UUID NOT NULL REFERENCES auth.users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.ops_assets ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────
-- 3. ops_banners — Draft→Published workflow + version
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ops_banners (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  placement   TEXT NOT NULL DEFAULT 'home_top'
              CHECK (placement IN ('home_top', 'home_bottom', 'discover_top',
                                    'chat_top', 'profile_banner', 'popup')),
  image_url   TEXT NOT NULL DEFAULT '',
  link_url    TEXT DEFAULT '',
  link_type   TEXT DEFAULT 'internal'
              CHECK (link_type IN ('internal', 'external', 'none')),
  status      TEXT NOT NULL DEFAULT 'draft'
              CHECK (status IN ('draft', 'in_review', 'published', 'archived')),
  priority    INT NOT NULL DEFAULT 0,
  start_at    TIMESTAMPTZ,
  end_at      TIMESTAMPTZ,
  target_audience TEXT DEFAULT 'all'
              CHECK (target_audience IN ('all', 'fans', 'creators', 'vip')),
  version     INT NOT NULL DEFAULT 1,
  published_snapshot JSONB,
  created_by  UUID NOT NULL REFERENCES auth.users(id),
  updated_by  UUID REFERENCES auth.users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.ops_banners ENABLE ROW LEVEL SECURITY;

COMMENT ON COLUMN public.ops_banners.version IS
  'Optimistic locking: UPDATE must include WHERE version = expected_version';
COMMENT ON COLUMN public.ops_banners.published_snapshot IS
  'Frozen JSONB copy of the banner state at publish time, used for rollback';

-- ────────────────────────────────────────────────
-- 4. ops_feature_flags — Feature flag management
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ops_feature_flags (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_key        TEXT NOT NULL UNIQUE,
  title           TEXT NOT NULL,
  description     TEXT DEFAULT '',
  status          TEXT NOT NULL DEFAULT 'draft'
                  CHECK (status IN ('draft', 'published', 'archived')),
  enabled         BOOLEAN NOT NULL DEFAULT false,
  rollout_percent INT NOT NULL DEFAULT 100
                  CHECK (rollout_percent BETWEEN 0 AND 100),
  payload         JSONB DEFAULT '{}',
  version         INT NOT NULL DEFAULT 1,
  published_snapshot JSONB,
  created_by      UUID NOT NULL REFERENCES auth.users(id),
  updated_by      UUID REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.ops_feature_flags ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────
-- 5. ops_audit_log — Diff-only change tracking
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ops_audit_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    UUID NOT NULL REFERENCES auth.users(id),
  actor_role  TEXT NOT NULL,
  action      TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id   UUID,
  before      JSONB,      -- Changed fields only (diff, not full row)
  after       JSONB,      -- Changed fields only (diff, not full row)
  metadata    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.ops_audit_log ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_ops_audit_entity
  ON public.ops_audit_log (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_ops_audit_actor
  ON public.ops_audit_log (actor_id);
CREATE INDEX IF NOT EXISTS idx_ops_audit_created
  ON public.ops_audit_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ops_audit_diff
  ON public.ops_audit_log USING GIN (after jsonb_path_ops);

COMMENT ON COLUMN public.ops_audit_log.before IS
  'JSONB diff: only fields that changed (old values). NULL for create actions.';
COMMENT ON COLUMN public.ops_audit_log.after IS
  'JSONB diff: only fields that changed (new values). NULL for delete actions.';

-- ────────────────────────────────────────────────
-- 6. app_public_config — Published-only view for apps
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.app_public_config (
  id          TEXT PRIMARY KEY DEFAULT 'current',
  banners     JSONB NOT NULL DEFAULT '[]',
  flags       JSONB NOT NULL DEFAULT '{}',
  config_hash TEXT DEFAULT '',
  refreshed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.app_public_config ENABLE ROW LEVEL SECURITY;

-- Seed initial row
INSERT INTO public.app_public_config (id, banners, flags, config_hash)
VALUES ('current', '[]', '{}', '')
ON CONFLICT (id) DO NOTHING;

COMMENT ON TABLE public.app_public_config IS
  'Single-row table holding published banners + flags. Read by Flutter/web clients.';
COMMENT ON COLUMN public.app_public_config.config_hash IS
  'MD5 hash of published data for ETag-like conditional caching in Flutter.';

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- ────────────────────────────────────────────────
-- F1. is_ops_staff — Role-level check
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_ops_staff(
  min_role TEXT DEFAULT 'viewer'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
  role_levels CONSTANT INT[] := ARRAY[1, 2, 3, 4]; -- viewer, operator, publisher, admin
  role_names  CONSTANT TEXT[] := ARRAY['viewer', 'operator', 'publisher', 'admin'];
  v_user_level INT;
  v_min_level  INT;
BEGIN
  -- Get current user role
  SELECT role INTO v_role
  FROM ops_staff
  WHERE user_id = auth.uid();

  IF v_role IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Map role names to levels
  v_user_level := array_position(role_names, v_role);
  v_min_level  := array_position(role_names, min_role);

  IF v_user_level IS NULL OR v_min_level IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN v_user_level >= v_min_level;
END;
$$;

-- ────────────────────────────────────────────────
-- F2. log_ops_audit — Diff-only audit logging
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.log_ops_audit(
  p_action      TEXT,
  p_entity_type TEXT,
  p_entity_id   UUID,
  p_before      JSONB DEFAULT NULL,
  p_after       JSONB DEFAULT NULL,
  p_metadata    JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_role TEXT;
  v_diff_before JSONB;
  v_diff_after  JSONB;
  v_log_id UUID;
BEGIN
  -- Get actor role
  SELECT role INTO v_actor_role
  FROM ops_staff
  WHERE user_id = auth.uid();

  -- Calculate diff: only changed fields
  IF p_before IS NOT NULL AND p_after IS NOT NULL THEN
    -- Extract keys that differ between before and after
    SELECT
      jsonb_object_agg(key, p_before -> key),
      jsonb_object_agg(key, p_after -> key)
    INTO v_diff_before, v_diff_after
    FROM (
      SELECT key
      FROM jsonb_each(p_after)
      WHERE p_before -> key IS DISTINCT FROM p_after -> key
      UNION
      SELECT key
      FROM jsonb_each(p_before)
      WHERE NOT p_after ? key
    ) diff_keys(key);
  ELSE
    -- Create: no before; Delete: no after
    v_diff_before := p_before;
    v_diff_after  := p_after;
  END IF;

  INSERT INTO ops_audit_log (
    actor_id, actor_role, action, entity_type, entity_id,
    before, after, metadata
  ) VALUES (
    auth.uid(),
    COALESCE(v_actor_role, 'unknown'),
    p_action,
    p_entity_type,
    p_entity_id,
    v_diff_before,
    v_diff_after,
    p_metadata
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

-- ────────────────────────────────────────────────
-- F3. refresh_app_public_config — Publish snapshot
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.refresh_app_public_config()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_banners JSONB;
  v_flags   JSONB;
  v_hash    TEXT;
BEGIN
  -- Collect published banners (active period)
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', id,
      'title', title,
      'placement', placement,
      'image_url', image_url,
      'link_url', link_url,
      'link_type', link_type,
      'priority', priority,
      'target_audience', target_audience,
      'start_at', start_at,
      'end_at', end_at
    ) ORDER BY priority DESC, created_at DESC
  ), '[]'::jsonb)
  INTO v_banners
  FROM ops_banners
  WHERE status = 'published'
    AND (start_at IS NULL OR start_at <= now())
    AND (end_at IS NULL OR end_at > now());

  -- Collect published flags
  SELECT COALESCE(jsonb_object_agg(
    flag_key,
    jsonb_build_object(
      'enabled', enabled,
      'rollout_percent', rollout_percent,
      'payload', payload
    )
  ), '{}'::jsonb)
  INTO v_flags
  FROM ops_feature_flags
  WHERE status = 'published';

  -- Calculate config hash for ETag-like caching
  v_hash := md5(v_banners::text || v_flags::text);

  -- Upsert the single config row
  INSERT INTO app_public_config (id, banners, flags, config_hash, refreshed_at)
  VALUES ('current', v_banners, v_flags, v_hash, now())
  ON CONFLICT (id) DO UPDATE SET
    banners      = EXCLUDED.banners,
    flags        = EXCLUDED.flags,
    config_hash  = EXCLUDED.config_hash,
    refreshed_at = EXCLUDED.refreshed_at;
END;
$$;

-- ============================================================
-- RLS POLICIES
-- ============================================================

-- ── ops_staff ──
CREATE POLICY "ops_staff_select" ON public.ops_staff
  FOR SELECT USING (is_ops_staff());

CREATE POLICY "ops_staff_insert" ON public.ops_staff
  FOR INSERT WITH CHECK (is_ops_staff('admin'));

CREATE POLICY "ops_staff_update" ON public.ops_staff
  FOR UPDATE USING (is_ops_staff('admin'));

CREATE POLICY "ops_staff_delete" ON public.ops_staff
  FOR DELETE USING (is_ops_staff('admin'));

-- ── ops_assets ──
CREATE POLICY "ops_assets_select" ON public.ops_assets
  FOR SELECT USING (is_ops_staff());

CREATE POLICY "ops_assets_insert" ON public.ops_assets
  FOR INSERT WITH CHECK (is_ops_staff('operator'));

CREATE POLICY "ops_assets_delete" ON public.ops_assets
  FOR DELETE USING (is_ops_staff('operator'));

-- ── ops_banners ──
CREATE POLICY "ops_banners_select" ON public.ops_banners
  FOR SELECT USING (is_ops_staff());

CREATE POLICY "ops_banners_insert" ON public.ops_banners
  FOR INSERT WITH CHECK (is_ops_staff('operator'));

CREATE POLICY "ops_banners_update" ON public.ops_banners
  FOR UPDATE USING (is_ops_staff('operator'));

CREATE POLICY "ops_banners_delete" ON public.ops_banners
  FOR DELETE USING (is_ops_staff('admin'));

-- ── ops_feature_flags ──
CREATE POLICY "ops_flags_select" ON public.ops_feature_flags
  FOR SELECT USING (is_ops_staff());

CREATE POLICY "ops_flags_insert" ON public.ops_feature_flags
  FOR INSERT WITH CHECK (is_ops_staff('operator'));

CREATE POLICY "ops_flags_update" ON public.ops_feature_flags
  FOR UPDATE USING (is_ops_staff('operator'));

CREATE POLICY "ops_flags_delete" ON public.ops_feature_flags
  FOR DELETE USING (is_ops_staff('admin'));

-- ── ops_audit_log ──
CREATE POLICY "ops_audit_select" ON public.ops_audit_log
  FOR SELECT USING (is_ops_staff());

-- No insert/update/delete via client; only via log_ops_audit() SECURITY DEFINER

-- ── app_public_config — Public read ──
CREATE POLICY "app_config_public_read" ON public.app_public_config
  FOR SELECT USING (true);

-- No client-side writes; only via refresh_app_public_config() SECURITY DEFINER

-- ============================================================
-- GRANTS (Least Privilege)
-- ============================================================
REVOKE ALL ON ops_staff FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ops_staff TO authenticated;

REVOKE ALL ON ops_assets FROM authenticated;
GRANT SELECT, INSERT, DELETE ON ops_assets TO authenticated;

REVOKE ALL ON ops_banners FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ops_banners TO authenticated;

REVOKE ALL ON ops_feature_flags FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ops_feature_flags TO authenticated;

REVOKE ALL ON ops_audit_log FROM authenticated;
GRANT SELECT ON ops_audit_log TO authenticated;

-- app_public_config: anon + authenticated can read
GRANT SELECT ON app_public_config TO anon;
GRANT SELECT ON app_public_config TO authenticated;

-- ============================================================
-- UPDATED_AT TRIGGER (reuse pattern from existing migrations)
-- ============================================================
CREATE OR REPLACE FUNCTION public.ops_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_ops_staff_updated
  BEFORE UPDATE ON ops_staff
  FOR EACH ROW EXECUTE FUNCTION ops_set_updated_at();

CREATE TRIGGER trg_ops_banners_updated
  BEFORE UPDATE ON ops_banners
  FOR EACH ROW EXECUTE FUNCTION ops_set_updated_at();

CREATE TRIGGER trg_ops_flags_updated
  BEFORE UPDATE ON ops_feature_flags
  FOR EACH ROW EXECUTE FUNCTION ops_set_updated_at();

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_ops_banners_status
  ON public.ops_banners (status);
CREATE INDEX IF NOT EXISTS idx_ops_banners_placement
  ON public.ops_banners (placement, status);
CREATE INDEX IF NOT EXISTS idx_ops_flags_status
  ON public.ops_feature_flags (status);
CREATE INDEX IF NOT EXISTS idx_ops_flags_key
  ON public.ops_feature_flags (flag_key);

-- ============================================================
-- STORAGE BUCKET: ops-assets
-- ============================================================
-- Note: Storage bucket creation is typically done via Dashboard
-- or supabase CLI. Included here as documentation / reference.
-- If using CLI: supabase storage create ops-assets --public
--
-- Bucket policies should be:
--   READ:  public (anyone can view published banner images)
--   WRITE: only ops_staff (checked via is_ops_staff())
