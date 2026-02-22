-- =====================================================
-- Migration: 102_security_audit_p0_fixes.sql
-- Purpose: P0 security audit fixes
--
-- Fixes:
--   1. user_presence SELECT policy: restrict to channel subscribers/owner
--   2. message_reactions SELECT policy: restrict to channel subscribers/owner
--   3. admin_audit_log INSERT policy: restrict to service_role only
--   4. SET search_path for remaining SECURITY DEFINER trigger functions
-- =====================================================

BEGIN;

-- =====================================================
-- P0-1a: Tighten user_presence SELECT policy
--
-- Before: auth.uid() IS NOT NULL (any logged-in user sees all presence)
-- After:  Only channel artist or active subscriber can see presence
--         for users in that channel
-- =====================================================

DROP POLICY IF EXISTS "Users can view presence of their channel connections"
  ON user_presence;

CREATE POLICY "Users can view presence in their channels"
  ON user_presence FOR SELECT
  USING (
    -- Users can always see their own presence
    user_id = auth.uid()
    OR
    -- Channel artist can see presence of users in their channel
    EXISTS (
      SELECT 1 FROM channels c
      WHERE c.id = user_presence.channel_id
      AND c.artist_id = auth.uid()
    )
    OR
    -- Active subscriber can see presence in their subscribed channel
    EXISTS (
      SELECT 1 FROM subscriptions s
      WHERE s.channel_id = user_presence.channel_id
      AND s.user_id = auth.uid()
      AND s.is_active = true
    )
  );

-- =====================================================
-- P0-1b: Tighten message_reactions SELECT policy
--
-- Before: auth.uid() IS NOT NULL (any logged-in user sees all reactions)
-- After:  Only channel artist or active subscriber can see reactions
--         for messages in that channel
-- =====================================================

DROP POLICY IF EXISTS "Users can view reactions"
  ON message_reactions;

CREATE POLICY "Users can view reactions in their channels"
  ON message_reactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM messages m
      WHERE m.id = message_reactions.message_id
      AND (
        -- Channel artist
        EXISTS (
          SELECT 1 FROM channels c
          WHERE c.id = m.channel_id
          AND c.artist_id = auth.uid()
        )
        OR
        -- Active subscriber
        EXISTS (
          SELECT 1 FROM subscriptions s
          WHERE s.channel_id = m.channel_id
          AND s.user_id = auth.uid()
          AND s.is_active = true
        )
      )
    )
  );

-- =====================================================
-- P0-2: Restrict admin_audit_log INSERT
--
-- Before: WITH CHECK (true) — any authenticated user can INSERT
-- After:  Only service_role can INSERT (via log_admin_action function)
--
-- Note: Migration 101 already revoked EXECUTE on log_admin_action
--       from authenticated. This closes the remaining direct-INSERT path.
-- =====================================================

DROP POLICY IF EXISTS "System can insert audit log"
  ON admin_audit_log;

-- Deny all client-side inserts; only service_role bypasses RLS
-- (Edge Functions / triggers running as service_role can still insert)
CREATE POLICY "Only service_role can insert audit log"
  ON admin_audit_log FOR INSERT
  WITH CHECK (false);

-- =====================================================
-- P0-3: SET search_path for remaining SECURITY DEFINER functions
--
-- These trigger functions were created after migration 053
-- and are missing search_path hardening.
-- =====================================================

-- 074_welcome_chat_and_tier_gated.sql: send_welcome_message trigger
DO $$ BEGIN
  ALTER FUNCTION public.send_welcome_message() SET search_path = public;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function send_welcome_message does not exist, skipping';
END $$;

-- 079_fan_ads.sql: set_fan_ads_updated_at trigger
DO $$ BEGIN
  ALTER FUNCTION public.set_fan_ads_updated_at() SET search_path = public;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function set_fan_ads_updated_at does not exist, skipping';
END $$;

COMMIT;
