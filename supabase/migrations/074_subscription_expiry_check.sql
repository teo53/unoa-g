-- =====================================================
-- Migration: 074_subscription_expiry_check.sql
-- Purpose: Add expires_at checks to all subscription-dependent access controls
-- Risk: P0-04 — subscriptions with is_active=true but expires_at in the past
--        still grant full access because no query checks expires_at.
-- Fix: Add (expires_at IS NULL OR expires_at > now()) to every subscription
--       check in RLS policies and SECURITY DEFINER RPCs.
-- Pre-deploy impact check:
--   SELECT COUNT(*) FROM subscriptions
--   WHERE expires_at < now() AND is_active = true;
-- =====================================================

BEGIN;

-- ============================================
-- 1. messages RLS (from 002_rls_policies.sql)
-- ============================================

-- 1a. "Users can view subscribed broadcasts"
DROP POLICY IF EXISTS "Users can view subscribed broadcasts" ON messages;

CREATE POLICY "Users can view subscribed broadcasts"
  ON messages FOR SELECT
  USING (
    delivery_scope = 'broadcast'
    AND deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM subscriptions
      WHERE channel_id = messages.channel_id
        AND user_id = auth.uid()
        AND is_active = true
        AND (expires_at IS NULL OR expires_at > now())
    )
  );

-- 1b. "Subscribers can insert replies"
DROP POLICY IF EXISTS "Subscribers can insert replies" ON messages;

CREATE POLICY "Subscribers can insert replies"
  ON messages FOR INSERT
  WITH CHECK (
    sender_type = 'fan'
    AND delivery_scope = 'direct_reply'
    AND sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM subscriptions
      WHERE channel_id = messages.channel_id
        AND user_id = auth.uid()
        AND is_active = true
        AND (expires_at IS NULL OR expires_at > now())
    )
  );

-- 1c. "Subscribers can insert donation messages"
DROP POLICY IF EXISTS "Subscribers can insert donation messages" ON messages;

CREATE POLICY "Subscribers can insert donation messages"
  ON messages FOR INSERT
  WITH CHECK (
    sender_type = 'fan'
    AND delivery_scope = 'donation_message'
    AND sender_id = auth.uid()
    AND donation_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM subscriptions
      WHERE channel_id = messages.channel_id
        AND user_id = auth.uid()
        AND is_active = true
        AND (expires_at IS NULL OR expires_at > now())
    )
  );

-- ============================================
-- 2. message_polls RLS (from 007_messages_extended.sql)
-- ============================================

-- 2a. "Anyone can view polls in their channels"
DROP POLICY IF EXISTS "Anyone can view polls in their channels" ON message_polls;

CREATE POLICY "Anyone can view polls in their channels"
  ON message_polls FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM messages m
      WHERE m.id = message_polls.message_id
      AND (
        EXISTS (SELECT 1 FROM channels c WHERE c.id = m.channel_id AND c.artist_id = auth.uid())
        OR
        EXISTS (
          SELECT 1 FROM subscriptions s
          WHERE s.channel_id = m.channel_id
            AND s.user_id = auth.uid()
            AND s.is_active = true
            AND (s.expires_at IS NULL OR s.expires_at > now())
        )
      )
    )
  );

-- 2b. "Users can vote on accessible polls"
DROP POLICY IF EXISTS "Users can vote on accessible polls" ON poll_votes;

CREATE POLICY "Users can vote on accessible polls"
  ON poll_votes FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM message_polls mp
      JOIN messages m ON m.id = mp.message_id
      WHERE mp.id = poll_votes.poll_id
      AND (mp.ends_at IS NULL OR mp.ends_at > now())
      AND EXISTS (
        SELECT 1 FROM subscriptions s
        WHERE s.channel_id = m.channel_id
          AND s.user_id = auth.uid()
          AND s.is_active = true
          AND (s.expires_at IS NULL OR s.expires_at > now())
      )
    )
  );

-- ============================================
-- 3. typing_indicators RLS (from 007_messages_extended.sql)
-- ============================================

DROP POLICY IF EXISTS "Users can view typing in their channels" ON typing_indicators;

CREATE POLICY "Users can view typing in their channels"
  ON typing_indicators FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM subscriptions s
      WHERE s.channel_id = typing_indicators.channel_id
        AND s.user_id = auth.uid()
        AND s.is_active = true
        AND (s.expires_at IS NULL OR s.expires_at > now())
    )
    OR
    EXISTS (
      SELECT 1 FROM channels c
      WHERE c.id = typing_indicators.channel_id AND c.artist_id = auth.uid()
    )
  );

-- ============================================
-- 4. get_user_chat_thread RPC (from 060_chat_thread_subscription_check.sql)
-- ============================================

CREATE OR REPLACE FUNCTION public.get_user_chat_thread(
  p_channel_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_before_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  channel_id UUID,
  sender_id UUID,
  sender_type TEXT,
  delivery_scope TEXT,
  content TEXT,
  message_type TEXT,
  media_url TEXT,
  donation_id UUID,
  donation_amount INTEGER,
  is_highlighted BOOLEAN,
  created_at TIMESTAMPTZ,
  is_read BOOLEAN
) AS $$
BEGIN
  -- AUTH CHECK: active non-expired subscriber or channel artist
  IF NOT EXISTS (
    SELECT 1 FROM public.subscriptions s
    WHERE s.channel_id = p_channel_id
      AND s.user_id = auth.uid()
      AND s.is_active = true
      AND (s.expires_at IS NULL OR s.expires_at > now())
  ) AND NOT EXISTS (
    SELECT 1 FROM public.channels c
    WHERE c.id = p_channel_id
      AND c.artist_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: no active subscription for this channel';
  END IF;

  RETURN QUERY
  SELECT
    m.id,
    m.channel_id,
    m.sender_id,
    m.sender_type,
    m.delivery_scope,
    m.content,
    m.message_type,
    m.media_url,
    m.donation_id,
    m.donation_amount,
    m.is_highlighted,
    m.created_at,
    COALESCE(md.is_read, TRUE) as is_read
  FROM public.messages m
  LEFT JOIN public.message_delivery md ON m.id = md.message_id AND md.user_id = auth.uid()
  WHERE m.channel_id = p_channel_id
    AND m.deleted_at IS NULL
    AND (
      (m.delivery_scope = 'broadcast')
      OR
      (m.delivery_scope IN ('direct_reply', 'donation_message') AND m.sender_id = auth.uid())
      OR
      (m.delivery_scope = 'donation_reply' AND m.target_user_id = auth.uid())
    )
    AND (p_before_id IS NULL OR m.created_at < (SELECT msg.created_at FROM public.messages msg WHERE msg.id = p_before_id))
  ORDER BY m.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
   SET search_path = public;

COMMIT;
