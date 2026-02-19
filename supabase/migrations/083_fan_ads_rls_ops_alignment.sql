-- ============================================================
-- Migration 083: fan_ads RLS ops alignment
-- ============================================================
-- Allow ops staff to review/update fan ads through authenticated role:
--   - viewer+: SELECT
--   - operator+: UPDATE
-- ============================================================

DROP POLICY IF EXISTS fan_ads_ops_select ON public.fan_ads;
CREATE POLICY fan_ads_ops_select
  ON public.fan_ads
  FOR SELECT
  TO authenticated
  USING (public.is_ops_staff('viewer'));

DROP POLICY IF EXISTS fan_ads_ops_update ON public.fan_ads;
CREATE POLICY fan_ads_ops_update
  ON public.fan_ads
  FOR UPDATE
  TO authenticated
  USING (public.is_ops_staff('operator'))
  WITH CHECK (public.is_ops_staff('operator'));
