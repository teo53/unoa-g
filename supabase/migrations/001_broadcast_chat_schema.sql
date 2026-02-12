-- ============================================
-- UNO A - Broadcast Chat System Schema
-- Version: 1.0.0
-- ============================================

-- ============================================
-- 1. CHANNELS (one per artist)
-- ============================================
CREATE TABLE public.channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  avatar_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_artist_channel UNIQUE(artist_id)
);

CREATE INDEX idx_channels_artist_id ON channels(artist_id);
CREATE INDEX idx_channels_active ON channels(is_active) WHERE is_active = true;

-- ============================================
-- 2. SUBSCRIPTIONS (with age tracking)
-- ============================================
CREATE TABLE public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  tier TEXT NOT NULL DEFAULT 'STANDARD' CHECK (tier IN ('BASIC', 'STANDARD', 'VIP')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  auto_renew BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_user_channel_sub UNIQUE(user_id, channel_id)
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_channel ON subscriptions(channel_id);
CREATE INDEX idx_subscriptions_active ON subscriptions(channel_id, is_active) WHERE is_active = true;
CREATE INDEX idx_subscriptions_started_at ON subscriptions(started_at);

-- ============================================
-- 3. MESSAGES (broadcast + direct_reply + donation_reply)
-- ============================================
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('artist', 'fan')),

  -- delivery_scope determines visibility:
  -- 'broadcast' = visible to all subscribers
  -- 'direct_reply' = fan's regular reply (visible to fan + artist)
  -- 'donation_message' = fan's message with donation (visible to fan + artist)
  -- 'donation_reply' = artist's reply to donation (visible only to target fan + artist)
  delivery_scope TEXT NOT NULL CHECK (delivery_scope IN ('broadcast', 'direct_reply', 'donation_message', 'donation_reply')),

  -- For replies, link to parent message
  reply_to_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  -- For donation_reply or direct messages to specific user
  target_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Content
  content TEXT,
  message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'emoji', 'voice')),
  media_url TEXT,
  media_metadata JSONB,

  -- Donation info (for donation_message)
  -- FK to dt_donations added in 006_wallet_ledger.sql (table created there)
  donation_id UUID,
  donation_amount INTEGER, -- DT amount

  -- Highlighting/pinning for artist inbox
  is_highlighted BOOLEAN DEFAULT false,
  highlighted_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ -- Soft delete
);

-- Performance indexes
CREATE INDEX idx_messages_channel_created ON messages(channel_id, created_at DESC);
CREATE INDEX idx_messages_broadcast ON messages(channel_id, delivery_scope, created_at DESC)
  WHERE delivery_scope = 'broadcast';
CREATE INDEX idx_messages_fan_replies ON messages(channel_id, sender_id, created_at DESC)
  WHERE delivery_scope IN ('direct_reply', 'donation_message');
CREATE INDEX idx_messages_target_user ON messages(target_user_id, created_at DESC);
CREATE INDEX idx_messages_donation ON messages(donation_id) WHERE donation_id IS NOT NULL;
CREATE INDEX idx_messages_artist_inbox ON messages(channel_id, delivery_scope, is_highlighted, created_at DESC)
  WHERE delivery_scope IN ('direct_reply', 'donation_message');

-- ============================================
-- 4. MESSAGE_DELIVERY (per-user broadcast state)
-- ============================================
CREATE TABLE public.message_delivery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_delivery UNIQUE(message_id, user_id)
);

CREATE INDEX idx_delivery_user_unread ON message_delivery(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_delivery_message ON message_delivery(message_id);

-- ============================================
-- 5. REPLY_QUOTA (token system)
-- ============================================
CREATE TABLE public.reply_quota (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  tokens_available INTEGER NOT NULL DEFAULT 0 CHECK (tokens_available >= 0),
  tokens_used INTEGER NOT NULL DEFAULT 0 CHECK (tokens_used >= 0),
  last_broadcast_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  last_broadcast_at TIMESTAMPTZ,
  last_reply_at TIMESTAMPTZ,
  -- For long-reply fallback tracking
  fallback_available BOOLEAN DEFAULT false,
  fallback_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_user_channel_quota UNIQUE(user_id, channel_id)
);

CREATE INDEX idx_quota_user ON reply_quota(user_id);
CREATE INDEX idx_quota_channel ON reply_quota(channel_id);
CREATE INDEX idx_quota_last_broadcast ON reply_quota(last_broadcast_at);

-- ============================================
-- 6. POLICY_CONFIG (JSON-based configurable rules)
-- ============================================
CREATE TABLE public.policy_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value JSONB NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Default policy configuration (Fromm/Bubble style)
INSERT INTO policy_config (key, value, description) VALUES

-- ============================================
-- SUBSCRIPTION PRICING
-- ============================================
('subscription_pricing', '{
  "monthly_price_krw": 4900,
  "currency": "KRW",
  "billing_cycle": "monthly",
  "trial_days": 0,
  "auto_renewal": true
}', 'Subscription pricing per artist (4,900원/월)'),

-- ============================================
-- TOKEN RULES (Fromm/Bubble style)
-- ============================================
('token_rules', '{
  "default_tokens": 3,
  "max_tokens": 3,
  "tier_multipliers": {
    "BASIC": 1.0,
    "STANDARD": 1.0,
    "VIP": 1.0
  },
  "age_bonuses": []
}', 'Token allocation: 3 replies per artist broadcast'),

-- ============================================
-- LONG REPLY FALLBACK
-- ============================================
('long_reply_fallback', '{
  "enabled": true,
  "days_without_broadcast": 7,
  "fallback_tokens": 1
}', 'Allow 1 message if no broadcast for 7 days'),

-- ============================================
-- CHARACTER LIMITS (Bubble-style progression)
-- 구독 기념일 기준 글자수 증가
-- ============================================
('character_limits', '{
  "base_limit": 50,
  "progression": [
    {"min_days": 1, "max_chars": 50},
    {"min_days": 50, "max_chars": 50},
    {"min_days": 77, "max_chars": 77},
    {"min_days": 100, "max_chars": 100},
    {"min_days": 150, "max_chars": 150},
    {"min_days": 200, "max_chars": 200},
    {"min_days": 300, "max_chars": 300},
    {"min_days": 365, "max_chars": 300}
  ]
}', 'Reply character limit increases with subscription age'),

-- ============================================
-- MESSAGE LIMITS
-- ============================================
('message_limits', '{
  "max_donation_message_length": 100,
  "max_media_size_mb": 10,
  "rate_limit_per_minute": 5
}', 'Message content and rate limits'),

-- ============================================
-- DONATION REPLY RULES
-- ============================================
('donation_reply_rules', '{
  "enabled": true,
  "max_reply_length": 500,
  "reply_window_hours": 168
}', 'Artist can only reply to donation messages within 7 days');

-- ============================================
-- 7. HELPER VIEWS
-- ============================================

-- Subscription age view for token calculation
CREATE VIEW subscription_age_view AS
SELECT
  id,
  user_id,
  channel_id,
  tier,
  EXTRACT(DAY FROM (now() - started_at))::INTEGER as days_subscribed,
  is_active
FROM subscriptions;

-- User's chat thread view (fan perspective)
-- Shows: broadcasts + their own replies + artist replies to them
CREATE OR REPLACE VIEW user_chat_thread_view AS
SELECT
  m.id,
  m.channel_id,
  m.sender_id,
  m.sender_type,
  m.delivery_scope,
  m.reply_to_message_id,
  m.target_user_id,
  m.content,
  m.message_type,
  m.media_url,
  m.donation_id,
  m.donation_amount,
  m.is_highlighted,
  m.created_at,
  COALESCE(md.is_read, TRUE) as is_read,
  md.read_at
FROM messages m
LEFT JOIN message_delivery md ON m.id = md.message_id AND md.user_id = auth.uid()
WHERE m.deleted_at IS NULL
  AND (
    -- Broadcasts to channels user is subscribed to
    (m.delivery_scope = 'broadcast' AND EXISTS (
      SELECT 1 FROM subscriptions s
      WHERE s.channel_id = m.channel_id
        AND s.user_id = auth.uid()
        AND s.is_active = true
    ))
    OR
    -- User's own replies (regular or donation)
    (m.delivery_scope IN ('direct_reply', 'donation_message') AND m.sender_id = auth.uid())
    OR
    -- Artist replies to this user (donation replies)
    (m.delivery_scope = 'donation_reply' AND m.target_user_id = auth.uid())
  )
ORDER BY m.created_at ASC;

-- Artist inbox view (artist perspective)
-- Shows: all fan messages (regular replies + donation messages)
CREATE OR REPLACE VIEW artist_inbox_view AS
SELECT
  m.id,
  m.channel_id,
  m.sender_id,
  m.delivery_scope,
  m.content,
  m.message_type,
  m.media_url,
  m.donation_id,
  m.donation_amount,
  m.is_highlighted,
  m.created_at,
  s.tier as sender_tier,
  s.started_at as subscription_started,
  EXTRACT(DAY FROM (now() - s.started_at))::INTEGER as sender_days_subscribed
FROM messages m
LEFT JOIN subscriptions s ON s.user_id = m.sender_id AND s.channel_id = m.channel_id
WHERE m.delivery_scope IN ('direct_reply', 'donation_message')
  AND m.deleted_at IS NULL
  AND EXISTS (
    SELECT 1 FROM channels c
    WHERE c.id = m.channel_id AND c.artist_id = auth.uid()
  )
ORDER BY m.created_at DESC;
