-- ============================================================
-- Migration: 102_security_audit_p0_fixes.sql
-- Purpose: P0 security hardening (batch)
--
-- Fixes:
--   1. user_presence SELECT — restrict to channel members only
--   2. message_reactions SELECT — remove overly permissive policy from 007
--   3. admin_audit_log INSERT — verify lockdown
--   4. SECURITY DEFINER functions — add SET search_path = public
--   5. encrypt_sensitive / decrypt_sensitive — add SET search_path
--
-- Approach: Idempotent (DROP IF EXISTS + CREATE OR REPLACE).
--           Does NOT edit old migration files.
-- ============================================================

BEGIN;

-- ============================================================
-- 1. user_presence SELECT — restrict to channel members
-- ============================================================
-- Migration 007 created:
--   "Users can view presence of their channel connections"
--   USING (auth.uid() IS NOT NULL)
-- This leaks presence of ALL users across ALL channels.
-- Fix: restrict to channel artist + active subscribers.

DROP POLICY IF EXISTS "Users can view presence of their channel connections" ON user_presence;

CREATE POLICY "Channel members can view presence"
  ON user_presence
  FOR SELECT
  TO authenticated
  USING (
    -- Own presence
    user_id = auth.uid()
    OR
    -- Channel artist can see presence of users in their channel
    EXISTS (
      SELECT 1 FROM channels c
      WHERE c.id = user_presence.channel_id
        AND c.artist_id = auth.uid()
    )
    OR
    -- Active subscribers can see presence of users in same channel
    EXISTS (
      SELECT 1 FROM subscriptions s
      WHERE s.channel_id = user_presence.channel_id
        AND s.user_id = auth.uid()
        AND s.is_active = true
    )
  );

-- Also tighten the FOR ALL policy to truly be user_id = auth.uid() only
DROP POLICY IF EXISTS "Users can update own presence" ON user_presence;
CREATE POLICY "Users can update own presence"
  ON user_presence
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 2. message_reactions SELECT — drop overly permissive policy
-- ============================================================
-- Migration 007 created: "Users can view reactions"
--   USING (auth.uid() IS NOT NULL)
-- Migration 028 created: "Channel subscribers can view reactions"
--   (properly scoped to channel access)
-- The 007 policy was never dropped and OR's with 028's policy,
-- effectively granting any authenticated user access.
--
-- Also drop 007's INSERT/DELETE policies (different names from 028)
-- that may coexist.

DROP POLICY IF EXISTS "Users can view reactions" ON message_reactions;
DROP POLICY IF EXISTS "Users can add reactions" ON message_reactions;
DROP POLICY IF EXISTS "Users can remove own reactions" ON message_reactions;

-- Verify 028's policies exist (or re-create them)
DROP POLICY IF EXISTS "Users can add their own reactions" ON message_reactions;
CREATE POLICY "Users can add their own reactions"
  ON message_reactions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own reactions" ON message_reactions;
CREATE POLICY "Users can delete their own reactions"
  ON message_reactions
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Channel subscribers can view reactions" ON message_reactions;
CREATE POLICY "Channel subscribers can view reactions"
  ON message_reactions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM messages m
      JOIN subscriptions s ON m.channel_id = s.channel_id
      WHERE m.id = message_reactions.message_id
        AND s.user_id = auth.uid()
        AND s.is_active = true
    )
    OR
    EXISTS (
      SELECT 1 FROM messages m
      JOIN channels c ON m.channel_id = c.id
      WHERE m.id = message_reactions.message_id
        AND c.artist_id = auth.uid()
    )
  );

-- ============================================================
-- 3. admin_audit_log — verify INSERT lockdown
-- ============================================================
-- Migration 014: "System can insert audit log" WITH CHECK (true)
-- Migration 026: Dropped above, created "Secure audit log insert"
-- Migration 101: Revoked EXECUTE on log_admin_action from authenticated
--
-- Defensive: ensure the old permissive policy is definitely gone
DROP POLICY IF EXISTS "System can insert audit log" ON admin_audit_log;

-- ============================================================
-- 4. SECURITY DEFINER functions — add SET search_path = public
-- ============================================================
-- Functions from migrations 003-007 that were created without
-- SET search_path.  Migration 053 already applied these fixes;
-- repeating here as defensive/idempotent confirmation.
-- Using ALTER FUNCTION (no signature change, no body change).

-- 003_triggers.sql functions
ALTER FUNCTION public.refresh_reply_quotas() SET search_path = public;
ALTER FUNCTION public.validate_and_decrement_quota() SET search_path = public;
ALTER FUNCTION public.validate_donation_message() SET search_path = public;
ALTER FUNCTION public.validate_donation_reply() SET search_path = public;
ALTER FUNCTION public.create_broadcast_delivery() SET search_path = public;
ALTER FUNCTION public.enable_fallback_quotas(TIMESTAMPTZ) SET search_path = public;
ALTER FUNCTION public.get_user_chat_thread(UUID, INTEGER, UUID) SET search_path = public;
ALTER FUNCTION public.get_artist_inbox(UUID, TEXT, INTEGER, INTEGER) SET search_path = public;
ALTER FUNCTION public.get_chat_quota_summary(UUID, UUID) SET search_path = public;

-- 004_user_profiles.sql
ALTER FUNCTION public.handle_new_user() SET search_path = public;

-- 005_creator_profiles.sql
ALTER FUNCTION public.handle_new_creator_profile() SET search_path = public;

-- 006_wallet_ledger.sql
ALTER FUNCTION public.process_wallet_transaction(TEXT, UUID, UUID, INTEGER, TEXT, TEXT, UUID, TEXT, JSONB) SET search_path = public;

-- 007_messages_extended.sql
ALTER FUNCTION public.edit_message(UUID, TEXT, INTEGER) SET search_path = public;
ALTER FUNCTION public.delete_message_for_all(UUID) SET search_path = public;
ALTER FUNCTION public.hide_message_for_me(UUID) SET search_path = public;
ALTER FUNCTION public.pin_message(UUID) SET search_path = public;
ALTER FUNCTION public.update_presence(UUID, BOOLEAN, TEXT) SET search_path = public;

-- 028_add_message_reactions.sql (trigger functions)
ALTER FUNCTION public.update_reaction_count_on_insert() SET search_path = public;
ALTER FUNCTION public.update_reaction_count_on_delete() SET search_path = public;
ALTER FUNCTION public.get_message_reaction_info(UUID) SET search_path = public;
ALTER FUNCTION public.toggle_message_reaction(UUID, TEXT) SET search_path = public;

-- 026_security_hardening.sql (encrypt/decrypt missing SET search_path)
ALTER FUNCTION public.encrypt_sensitive(TEXT, TEXT) SET search_path = public;
ALTER FUNCTION public.decrypt_sensitive(TEXT) SET search_path = public;

-- 014_admin_policies.sql
ALTER FUNCTION public.is_admin(UUID) SET search_path = public;

-- ============================================================
-- 5. Verification block
-- ============================================================
DO $$
BEGIN
  -- Verify user_presence permissive policy is gone
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_presence'
      AND policyname = 'Users can view presence of their channel connections'
  ) THEN
    RAISE EXCEPTION 'Migration failed: old permissive user_presence policy still exists';
  END IF;

  -- Verify message_reactions permissive policy is gone
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'message_reactions'
      AND policyname = 'Users can view reactions'
  ) THEN
    RAISE EXCEPTION 'Migration failed: old permissive message_reactions policy still exists';
  END IF;

  -- Verify admin_audit_log old policy is gone
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'admin_audit_log'
      AND policyname = 'System can insert audit log'
  ) THEN
    RAISE EXCEPTION 'Migration failed: old permissive admin_audit_log INSERT policy still exists';
  END IF;

  RAISE NOTICE '102_security_audit_p0_fixes: all checks passed';
END $$;

COMMIT;
