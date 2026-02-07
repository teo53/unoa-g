-- ============================================
-- 032: Restrict user_profiles access, create public view
-- ============================================
-- Problem: "Authenticated can view public profiles" policy (004_user_profiles.sql:64-66)
-- exposes ALL fields including date_of_birth, guardian_phone, phone to any authenticated user.
-- Fix: Drop blanket SELECT policy, create a safe public view.

-- 1. Drop the overly-permissive blanket SELECT policy
DROP POLICY IF EXISTS "Authenticated can view public profiles" ON user_profiles;

-- 2. Create a narrow public view exposing ONLY safe fields
-- Sensitive fields excluded: date_of_birth, guardian_phone, guardian_consent_at,
--   age_verified_at, phone, notification_settings, ban_reason, ban_expires_at
CREATE OR REPLACE VIEW public.public_user_profiles AS
SELECT
  id,
  display_name,
  avatar_url,
  bio,
  role,
  locale,
  timezone,
  last_active_at,
  created_at
FROM public.user_profiles
WHERE is_banned = false;

-- 3. Grant SELECT on view to authenticated users
GRANT SELECT ON public.public_user_profiles TO authenticated;

-- 4. "Users can view own profile" policy (004:59-61) remains unchanged
--    → Users can still SELECT their own full profile via user_profiles table
-- 5. "Users can update own profile" policy (004:69-70) remains unchanged
-- 6. "Service role has full access" policy (if exists) remains unchanged
