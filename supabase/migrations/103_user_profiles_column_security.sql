-- ============================================================
-- Migration: 103_user_profiles_column_security.sql
-- Purpose: P0-1 — Block user self-escalation of role/ban/verified columns
--
-- Problem:
--   "Users can update own profile" policy allows any authenticated user
--   to UPDATE any column (including role, is_banned, email_verified, etc.)
--   as long as id = auth.uid().
--
-- Fix:
--   BEFORE UPDATE trigger on user_profiles that silently resets
--   protected columns to their OLD values when the caller is NOT
--   service_role.  This means:
--     - Normal users can update display_name, bio, avatar_url, etc.
--     - role, is_banned, email_verified, etc. are immune to user changes.
--     - Admin operations via service_role (Edge Functions) are unaffected.
--
-- Approach: Idempotent (CREATE OR REPLACE, DROP IF EXISTS).
-- ============================================================

BEGIN;

-- ============================================================
-- 1. Create trigger function to protect sensitive columns
-- ============================================================
CREATE OR REPLACE FUNCTION public.protect_user_profile_sensitive_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  jwt_role TEXT;
BEGIN
  -- service_role bypasses protection (admin operations via Edge Functions)
  -- Resolve role from JWT claim first, then fallback to DB role.
  jwt_role := coalesce(
    current_setting('request.jwt.claim.role', true),
    current_setting('role', true),
    'anon'
  );

  IF jwt_role IS DISTINCT FROM 'service_role' THEN
    -- Preserve original values for ALL protected columns
    -- These can only be changed via service_role (Edge Functions, admin API)
    NEW.role                := OLD.role;
    NEW.is_banned           := OLD.is_banned;
    NEW.banned_at           := OLD.banned_at;
    NEW.ban_reason          := OLD.ban_reason;
    NEW.ban_expires_at      := OLD.ban_expires_at;
    NEW.email_verified      := OLD.email_verified;
    NEW.age_verified_at     := OLD.age_verified_at;
    NEW.guardian_consent_at  := OLD.guardian_consent_at;
    NEW.guardian_phone      := OLD.guardian_phone;
    -- created_at should never change
    NEW.created_at          := OLD.created_at;
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================================
-- 2. Attach trigger (BEFORE UPDATE, runs before RLS WITH CHECK)
-- ============================================================
DROP TRIGGER IF EXISTS protect_user_profile_fields_trigger ON user_profiles;
DROP TRIGGER IF EXISTS protect_sensitive_columns ON user_profiles;

CREATE TRIGGER protect_sensitive_columns
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_user_profile_sensitive_columns();

-- ============================================================
-- 3. Verification block
-- ============================================================
DO $$
BEGIN
  -- Verify trigger exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.triggers
    WHERE trigger_name = 'protect_sensitive_columns'
      AND event_object_table = 'user_profiles'
  ) THEN
    RAISE EXCEPTION 'Migration failed: protect_sensitive_columns trigger not created';
  END IF;

  -- Verify old trigger was removed to avoid duplicate BEFORE UPDATE behavior
  IF EXISTS (
    SELECT 1 FROM information_schema.triggers
    WHERE trigger_name = 'protect_user_profile_fields_trigger'
      AND event_object_table = 'user_profiles'
  ) THEN
    RAISE EXCEPTION 'Migration failed: legacy protect_user_profile_fields_trigger still exists';
  END IF;

  -- Verify function exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'protect_user_profile_sensitive_columns'
  ) THEN
    RAISE EXCEPTION 'Migration failed: protect_user_profile_sensitive_columns function not created';
  END IF;

  RAISE NOTICE '103_user_profiles_column_security: P0-1 fix applied — role escalation blocked';
END $$;

COMMIT;
