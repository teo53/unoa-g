-- ============================================================
-- Migration 081: ops_banners source metadata for fan ads
-- ============================================================
-- Adds source_type/fan_ad_id to ops_banners and extends
-- refresh_app_public_config() banners JSON payload.
-- ============================================================

-- 1) ops_banners columns
ALTER TABLE public.ops_banners
  ADD COLUMN IF NOT EXISTS source_type TEXT NOT NULL DEFAULT 'ops';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'ops_banners_source_type_check'
      AND conrelid = 'public.ops_banners'::regclass
  ) THEN
    ALTER TABLE public.ops_banners
      ADD CONSTRAINT ops_banners_source_type_check
      CHECK (source_type IN ('ops', 'fan_ad', 'creator_promo'));
  END IF;
END;
$$;

ALTER TABLE public.ops_banners
  ADD COLUMN IF NOT EXISTS fan_ad_id UUID;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'ops_banners_fan_ad_id_fkey'
      AND conrelid = 'public.ops_banners'::regclass
  ) THEN
    ALTER TABLE public.ops_banners
      ADD CONSTRAINT ops_banners_fan_ad_id_fkey
      FOREIGN KEY (fan_ad_id)
      REFERENCES public.fan_ads(id)
      ON DELETE SET NULL;
  END IF;
END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_ops_banners_fan_ad_id
  ON public.ops_banners (fan_ad_id)
  WHERE fan_ad_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ops_banners_source_type
  ON public.ops_banners (source_type, status);

COMMENT ON COLUMN public.ops_banners.source_type IS
  'Banner source: ops | fan_ad | creator_promo';
COMMENT ON COLUMN public.ops_banners.fan_ad_id IS
  'Origin fan ad id when source_type=fan_ad';

-- 2) refresh_app_public_config() redefinition
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
      'end_at', end_at,
      'source_type', source_type,
      'fan_ad_id', fan_ad_id
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
