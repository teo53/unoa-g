-- ============================================
-- UNO A - Row Level Security Policies
-- Version: 1.0.0
-- ============================================

-- Enable RLS on all tables
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_delivery ENABLE ROW LEVEL SECURITY;
ALTER TABLE reply_quota ENABLE ROW LEVEL SECURITY;
ALTER TABLE policy_config ENABLE ROW LEVEL SECURITY;

-- ============================================
-- CHANNELS POLICIES
-- ============================================

-- Anyone can view active channels
CREATE POLICY "Public can view active channels"
  ON channels FOR SELECT
  USING (is_active = true);

-- Artists can manage their own channel
CREATE POLICY "Artist can manage own channel"
  ON channels FOR ALL
  USING (artist_id = auth.uid());

-- ============================================
-- SUBSCRIPTIONS POLICIES
-- ============================================

-- Users can view their own subscriptions
CREATE POLICY "Users can view own subscriptions"
  ON subscriptions FOR SELECT
  USING (user_id = auth.uid());

-- Artists can view subscribers to their channel
CREATE POLICY "Artists can view channel subscribers"
  ON subscriptions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM channels
      WHERE id = subscriptions.channel_id AND artist_id = auth.uid()
    )
  );

-- Service role can manage subscriptions (for payment systems)
CREATE POLICY "Service can manage subscriptions"
  ON subscriptions FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');

-- ============================================
-- MESSAGES POLICIES
-- ============================================

-- Users can view broadcasts they're subscribed to
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
    )
  );

-- Users can view their own replies
CREATE POLICY "Users can view own replies"
  ON messages FOR SELECT
  USING (
    delivery_scope IN ('direct_reply', 'donation_message')
    AND deleted_at IS NULL
    AND sender_id = auth.uid()
  );

-- Users can view donation replies addressed to them
CREATE POLICY "Users can view donation replies to them"
  ON messages FOR SELECT
  USING (
    delivery_scope = 'donation_reply'
    AND deleted_at IS NULL
    AND target_user_id = auth.uid()
  );

-- Artists can view all replies to their channel
CREATE POLICY "Artists can view channel replies"
  ON messages FOR SELECT
  USING (
    delivery_scope IN ('direct_reply', 'donation_message', 'donation_reply')
    AND deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM channels
      WHERE id = messages.channel_id AND artist_id = auth.uid()
    )
  );

-- Artists can insert broadcasts
CREATE POLICY "Artists can insert broadcasts"
  ON messages FOR INSERT
  WITH CHECK (
    sender_type = 'artist'
    AND delivery_scope = 'broadcast'
    AND EXISTS (
      SELECT 1 FROM channels
      WHERE id = messages.channel_id AND artist_id = auth.uid()
    )
  );

-- Subscribers can insert regular replies (if they have tokens)
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
    )
    -- Token check is done by trigger
  );

-- Subscribers can insert donation messages (no token required)
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
    )
  );

-- Artists can insert donation replies (only to donation messages)
CREATE POLICY "Artists can insert donation replies"
  ON messages FOR INSERT
  WITH CHECK (
    sender_type = 'artist'
    AND delivery_scope = 'donation_reply'
    AND target_user_id IS NOT NULL
    AND reply_to_message_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM channels
      WHERE id = messages.channel_id AND artist_id = auth.uid()
    )
    -- Must be replying to a donation message
    AND EXISTS (
      SELECT 1 FROM messages m
      WHERE m.id = messages.reply_to_message_id
        AND m.delivery_scope = 'donation_message'
    )
  );

-- Artists can highlight messages in their channel
CREATE POLICY "Artists can update highlight status"
  ON messages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM channels
      WHERE id = messages.channel_id AND artist_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM channels
      WHERE id = messages.channel_id AND artist_id = auth.uid()
    )
  );

-- ============================================
-- MESSAGE_DELIVERY POLICIES
-- ============================================

-- Users can view their own delivery status
CREATE POLICY "Users can view own delivery status"
  ON message_delivery FOR SELECT
  USING (user_id = auth.uid());

-- Users can update their own read status
CREATE POLICY "Users can update own read status"
  ON message_delivery FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- System can create delivery records
CREATE POLICY "System can create delivery"
  ON message_delivery FOR INSERT
  WITH CHECK (auth.jwt()->>'role' = 'service_role' OR auth.uid() IS NOT NULL);

-- ============================================
-- REPLY_QUOTA POLICIES
-- ============================================

-- Users can view their own quota
CREATE POLICY "Users can view own quota"
  ON reply_quota FOR SELECT
  USING (user_id = auth.uid());

-- System can manage quotas (via triggers)
CREATE POLICY "System can manage quotas"
  ON reply_quota FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');

-- ============================================
-- POLICY_CONFIG POLICIES
-- ============================================

-- Anyone can read active policies
CREATE POLICY "Anyone can read active policies"
  ON policy_config FOR SELECT
  USING (is_active = true);

-- Only admins can modify policies
CREATE POLICY "Admins can manage policies"
  ON policy_config FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');
