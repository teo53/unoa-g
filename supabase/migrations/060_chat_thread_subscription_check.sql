-- =====================================================
-- Migration: 060_chat_thread_subscription_check.sql
-- Purpose: Add subscription/ownership checks to SECURITY DEFINER chat RPCs
-- Security: CRITICAL — prevents unauthenticated channel access
--
-- 문제: get_user_chat_thread는 SECURITY DEFINER이므로 RLS 우회.
--       channel_id만 알면 구독 없이 broadcast 메시지 조회 가능.
--       get_artist_inbox도 동일 — 채널 소유자 검증 없음.
--
-- 수정: 함수 앞단에 구독/소유자 검증 추가.
--       기존 반환 스키마 및 쿼리 로직은 동일.
-- =====================================================

BEGIN;

-- ============================================
-- 1. get_user_chat_thread: 구독 검증 추가
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
  -- AUTH CHECK: 구독자 또는 채널 아티스트만 접근 가능
  IF NOT EXISTS (
    SELECT 1 FROM public.subscriptions s
    WHERE s.channel_id = p_channel_id
      AND s.user_id = auth.uid()
      AND s.is_active = true
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

-- ============================================
-- 2. get_artist_inbox: 채널 소유자 검증 추가
-- ============================================
CREATE OR REPLACE FUNCTION public.get_artist_inbox(
  p_channel_id UUID,
  p_filter_type TEXT DEFAULT 'all',
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  sender_id UUID,
  sender_name TEXT,
  sender_avatar TEXT,
  sender_tier TEXT,
  sender_days_subscribed INTEGER,
  delivery_scope TEXT,
  content TEXT,
  donation_id UUID,
  donation_amount INTEGER,
  is_highlighted BOOLEAN,
  created_at TIMESTAMPTZ,
  has_artist_reply BOOLEAN
) AS $$
BEGIN
  -- AUTH CHECK: 채널 아티스트만 접근 가능
  IF NOT EXISTS (
    SELECT 1 FROM public.channels c
    WHERE c.id = p_channel_id
      AND c.artist_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: only channel owner can view inbox';
  END IF;

  RETURN QUERY
  SELECT
    m.id,
    m.sender_id,
    COALESCE(p.raw_user_meta_data->>'name', 'Unknown')::TEXT as sender_name,
    COALESCE(p.raw_user_meta_data->>'avatar_url', '')::TEXT as sender_avatar,
    COALESCE(s.tier, 'BASIC')::TEXT as sender_tier,
    COALESCE(EXTRACT(DAY FROM (now() - s.started_at))::INTEGER, 0) as sender_days_subscribed,
    m.delivery_scope,
    m.content,
    m.donation_id,
    m.donation_amount,
    m.is_highlighted,
    m.created_at,
    EXISTS (
      SELECT 1 FROM public.messages r
      WHERE r.reply_to_message_id = m.id
        AND r.sender_type = 'artist'
    ) as has_artist_reply
  FROM public.messages m
  LEFT JOIN auth.users p ON m.sender_id = p.id
  LEFT JOIN public.subscriptions s ON s.user_id = m.sender_id AND s.channel_id = m.channel_id
  WHERE m.channel_id = p_channel_id
    AND m.delivery_scope IN ('direct_reply', 'donation_message')
    AND m.deleted_at IS NULL
    AND (
      p_filter_type = 'all'
      OR (p_filter_type = 'donation' AND m.delivery_scope = 'donation_message')
      OR (p_filter_type = 'regular' AND m.delivery_scope = 'direct_reply')
      OR (p_filter_type = 'highlighted' AND m.is_highlighted = true)
    )
  ORDER BY m.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
   SET search_path = public;

COMMIT;
