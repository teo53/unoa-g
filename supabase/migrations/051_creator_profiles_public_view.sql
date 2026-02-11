-- =====================================================
-- Migration: 051_creator_profiles_public_view.sql
-- Purpose: F-05 — Prevent public exposure of sensitive columns in creator_profiles
--
-- Problem:
--   The "Public can view verified creators" RLS policy exposes ALL columns
--   including bank_account_number, resident_registration_number, etc.
--   PostgreSQL RLS operates at row level, not column level — so we cannot
--   selectively hide columns within a policy.
--
-- Solution:
--   1. Drop the overly permissive public SELECT policy
--   2. Keep only owner-level SELECT (creators can view their own full profile)
--   3. Create a PUBLIC VIEW with only non-sensitive columns
--   4. Grant anon + authenticated access to the view
--
-- IMPORTANT: After this migration, client code that queries creator_profiles
-- for public display MUST switch to creator_profiles_public view.
-- =====================================================

-- =====================================================
-- 1. DROP OVERLY PERMISSIVE PUBLIC SELECT POLICY
-- =====================================================
-- This policy allowed ANY user (even anon) to SELECT ALL columns
-- from verified creator_profiles — including sensitive financial data.
DROP POLICY IF EXISTS "Public can view verified creators" ON creator_profiles;

-- =====================================================
-- 2. ENSURE OWNER-ONLY SELECT EXISTS
-- =====================================================
-- "Creators can view own profile" should already exist (migration 005),
-- but ensure it's present for safety.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'creator_profiles'
    AND policyname = 'Creators can view own profile'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Creators can view own profile"
        ON creator_profiles FOR SELECT
        USING (user_id = auth.uid())
    $policy$;
  END IF;
END $$;

-- =====================================================
-- 3. ADD ADMIN SELECT POLICY (service_role + admins)
-- =====================================================
-- Admins and Edge Functions (service_role) need full access.
DROP POLICY IF EXISTS "Admin can view all creator profiles" ON creator_profiles;
CREATE POLICY "Admin can view all creator profiles"
  ON creator_profiles FOR SELECT
  USING (
    (current_setting('request.jwt.claims', true)::jsonb->>'role') = 'service_role'
    OR public.is_admin()
  );

-- =====================================================
-- 4. CREATE PUBLIC VIEW (sensitive columns excluded)
-- =====================================================
-- This view exposes ONLY the columns safe for public consumption.
-- No bank accounts, no resident registration numbers, no payout info.
CREATE OR REPLACE VIEW public.creator_profiles_public AS
SELECT
  id,
  user_id,
  channel_id,
  -- Display info (safe)
  stage_name,
  stage_name_en,
  profile_image_url,
  cover_image_url,
  short_bio,
  full_bio,
  -- Categories/tags (safe)
  category,
  tags,
  -- Social links (safe)
  social_links,
  -- Verification status (safe - no documents)
  verification_status,
  verified_at,
  -- Public stats (safe)
  total_subscribers,
  total_messages_sent,
  -- Timestamps
  created_at,
  updated_at
FROM creator_profiles
WHERE verification_status = 'verified';

-- EXCLUDED columns (sensitive):
-- bank_code, bank_name, bank_account_number, account_holder_name
-- resident_registration_number, business_registration_number
-- withholding_tax_rate, tax_type, payout_verified, payout_verified_at
-- verification_documents (may contain ID scans)
-- total_revenue_dt, total_revenue_krw (financial data)
-- onboarding_completed

-- =====================================================
-- 5. GRANT ACCESS TO PUBLIC VIEW
-- =====================================================
GRANT SELECT ON public.creator_profiles_public TO anon;
GRANT SELECT ON public.creator_profiles_public TO authenticated;

-- =====================================================
-- 6. ADD COMMENTS
-- =====================================================
COMMENT ON VIEW public.creator_profiles_public IS
'Public-safe view of creator profiles. Excludes all sensitive financial,
identity, and payout information. Use this view for public-facing queries
(discovery, search, profile pages). Never expose the base table directly
to public/anon users.';

-- =====================================================
-- 7. VERIFY MIGRATION
-- =====================================================
DO $$
BEGIN
  -- Verify the dangerous policy is removed
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'creator_profiles'
    AND policyname = 'Public can view verified creators'
  ) THEN
    RAISE EXCEPTION 'Migration failed: dangerous public policy still exists';
  END IF;

  -- Verify the view exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_name = 'creator_profiles_public'
    AND table_schema = 'public'
  ) THEN
    RAISE EXCEPTION 'Migration failed: creator_profiles_public view not created';
  END IF;

  RAISE NOTICE 'F-05 migration completed: creator_profiles sensitive columns protected';
  RAISE NOTICE 'IMPORTANT: Update client code to use creator_profiles_public for public queries';
END $$;
