-- ============================================
-- UNO A - Extended Messages Schema (KakaoTalk-grade features)
-- Version: 1.1.0
-- ============================================

-- ============================================
-- 1. ADD NEW COLUMNS TO MESSAGES TABLE
-- ============================================

-- Edit support
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT false;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS edit_history JSONB DEFAULT '[]';
-- edit_history format: [{"previous_content": "...", "edited_at": "..."}]

-- Pin support (max 3 per channel)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS pinned_at TIMESTAMPTZ;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS pinned_by UUID REFERENCES auth.users(id);

-- Reply/quote support
ALTER TABLE messages ADD COLUMN IF NOT EXISTS reply_to_content_preview TEXT;
-- Cached preview of replied message content (for display when original deleted)

-- Scheduled messages
ALTER TABLE messages ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS scheduled_status TEXT CHECK (scheduled_status IN ('pending', 'sent', 'cancelled'));

-- Delete for me (client-side hide)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS hidden_for_user_ids UUID[] DEFAULT '{}';

-- Extend message_type for new types
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_message_type_check;
ALTER TABLE messages ADD CONSTRAINT messages_message_type_check
  CHECK (message_type IN ('text', 'image', 'video', 'voice', 'file', 'poll', 'system'));

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_messages_pinned ON messages(channel_id, is_pinned)
  WHERE is_pinned = true;
CREATE INDEX IF NOT EXISTS idx_messages_scheduled ON messages(scheduled_at, scheduled_status)
  WHERE scheduled_status = 'pending';
CREATE INDEX IF NOT EXISTS idx_messages_edited ON messages(is_edited)
  WHERE is_edited = true;

-- ============================================
-- 2. POLLS SYSTEM
-- ============================================
CREATE TABLE IF NOT EXISTS public.message_polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE UNIQUE,
  question TEXT NOT NULL,
  options JSONB NOT NULL, -- [{id: "uuid", text: "Option 1"}, ...]
  allow_multiple BOOLEAN DEFAULT false,
  ends_at TIMESTAMPTZ,
  is_anonymous BOOLEAN DEFAULT false,
  show_results_before_end BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.poll_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES message_polls(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  option_ids TEXT[] NOT NULL, -- Array of option IDs voted for
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_poll_vote UNIQUE(poll_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_poll_votes_poll ON poll_votes(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_user ON poll_votes(user_id);

-- RLS for polls
ALTER TABLE message_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view polls in their channels"
  ON message_polls FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM messages m
      WHERE m.id = message_polls.message_id
      AND (
        -- Creator of channel
        EXISTS (SELECT 1 FROM channels c WHERE c.id = m.channel_id AND c.artist_id = auth.uid())
        OR
        -- Subscriber
        EXISTS (SELECT 1 FROM subscriptions s WHERE s.channel_id = m.channel_id AND s.user_id = auth.uid() AND s.is_active = true)
      )
    )
  );

CREATE POLICY "Creator can create polls"
  ON message_polls FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM messages m
      JOIN channels c ON c.id = m.channel_id
      WHERE m.id = message_polls.message_id
      AND c.artist_id = auth.uid()
    )
  );

CREATE POLICY "Users can view their own votes"
  ON poll_votes FOR SELECT
  USING (user_id = auth.uid());

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
        WHERE s.channel_id = m.channel_id AND s.user_id = auth.uid() AND s.is_active = true
      )
    )
  );

-- ============================================
-- 3. PRESENCE & TYPING INDICATORS
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_presence (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  channel_id UUID REFERENCES channels(id), -- Currently viewing channel
  is_online BOOLEAN DEFAULT false,
  last_seen_at TIMESTAMPTZ DEFAULT now(),
  device_type TEXT, -- 'ios', 'android', 'web'
  app_version TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_presence_channel ON user_presence(channel_id, is_online)
  WHERE is_online = true;
CREATE INDEX IF NOT EXISTS idx_presence_online ON user_presence(is_online, last_seen_at DESC);

-- Typing indicators (ephemeral, short TTL)
CREATE TABLE IF NOT EXISTS public.typing_indicators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT now() + INTERVAL '5 seconds',

  CONSTRAINT unique_typing UNIQUE(channel_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_typing_channel ON typing_indicators(channel_id, expires_at);

-- RLS
ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view presence of their channel connections"
  ON user_presence FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update own presence"
  ON user_presence FOR ALL
  USING (user_id = auth.uid());

CREATE POLICY "Users can view typing in their channels"
  ON typing_indicators FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM subscriptions s
      WHERE s.channel_id = typing_indicators.channel_id
      AND s.user_id = auth.uid() AND s.is_active = true
    )
    OR
    EXISTS (
      SELECT 1 FROM channels c
      WHERE c.id = typing_indicators.channel_id AND c.artist_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own typing"
  ON typing_indicators FOR ALL
  USING (user_id = auth.uid());

-- ============================================
-- 4. MESSAGE REACTIONS (Unicode emoji only)
-- ============================================
CREATE TABLE IF NOT EXISTS public.message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL, -- Unicode emoji only
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_reaction UNIQUE(message_id, user_id, emoji)
);

CREATE INDEX IF NOT EXISTS idx_reactions_message ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user ON message_reactions(user_id);

ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view reactions"
  ON message_reactions FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can add reactions"
  ON message_reactions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can remove own reactions"
  ON message_reactions FOR DELETE
  USING (user_id = auth.uid());

-- ============================================
-- 5. HELPER FUNCTIONS
-- ============================================

-- Edit message (creator only, within time window)
CREATE OR REPLACE FUNCTION public.edit_message(
  p_message_id UUID,
  p_new_content TEXT,
  p_edit_window_hours INT DEFAULT 24
)
RETURNS messages AS $$
DECLARE
  v_message messages;
  v_edit_history JSONB;
BEGIN
  -- Get message with lock
  SELECT * INTO v_message FROM messages WHERE id = p_message_id FOR UPDATE;

  IF v_message IS NULL THEN
    RAISE EXCEPTION 'Message not found';
  END IF;

  -- Check if user is the sender
  IF v_message.sender_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to edit this message';
  END IF;

  -- Check edit window
  IF v_message.created_at < now() - (p_edit_window_hours || ' hours')::INTERVAL THEN
    RAISE EXCEPTION 'Edit window has expired';
  END IF;

  -- Add to edit history
  v_edit_history := COALESCE(v_message.edit_history, '[]'::JSONB);
  v_edit_history := v_edit_history || jsonb_build_object(
    'previous_content', v_message.content,
    'edited_at', now()
  );

  -- Update message
  UPDATE messages SET
    content = p_new_content,
    is_edited = true,
    edit_history = v_edit_history,
    updated_at = now()
  WHERE id = p_message_id
  RETURNING * INTO v_message;

  RETURN v_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Delete message for everyone (soft delete with tombstone)
CREATE OR REPLACE FUNCTION public.delete_message_for_all(p_message_id UUID)
RETURNS messages AS $$
DECLARE
  v_message messages;
BEGIN
  SELECT * INTO v_message FROM messages WHERE id = p_message_id FOR UPDATE;

  IF v_message IS NULL THEN
    RAISE EXCEPTION 'Message not found';
  END IF;

  -- Check if user is the sender or channel artist
  IF v_message.sender_id != auth.uid() AND NOT EXISTS (
    SELECT 1 FROM channels c WHERE c.id = v_message.channel_id AND c.artist_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not authorized to delete this message';
  END IF;

  -- Soft delete (tombstone)
  UPDATE messages SET
    deleted_at = now(),
    content = NULL,
    media_url = NULL,
    updated_at = now()
  WHERE id = p_message_id
  RETURNING * INTO v_message;

  RETURN v_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Hide message for current user only
CREATE OR REPLACE FUNCTION public.hide_message_for_me(p_message_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE messages SET
    hidden_for_user_ids = array_append(
      COALESCE(hidden_for_user_ids, '{}'),
      auth.uid()
    )
  WHERE id = p_message_id
  AND NOT (auth.uid() = ANY(COALESCE(hidden_for_user_ids, '{}')));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Pin message (max 3 per channel)
CREATE OR REPLACE FUNCTION public.pin_message(p_message_id UUID)
RETURNS messages AS $$
DECLARE
  v_message messages;
  v_pinned_count INT;
BEGIN
  SELECT * INTO v_message FROM messages WHERE id = p_message_id FOR UPDATE;

  IF v_message IS NULL THEN
    RAISE EXCEPTION 'Message not found';
  END IF;

  -- Check if user is channel artist
  IF NOT EXISTS (
    SELECT 1 FROM channels c WHERE c.id = v_message.channel_id AND c.artist_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only channel owner can pin messages';
  END IF;

  -- Check pin limit
  SELECT COUNT(*) INTO v_pinned_count
  FROM messages
  WHERE channel_id = v_message.channel_id AND is_pinned = true;

  IF v_pinned_count >= 3 AND NOT v_message.is_pinned THEN
    RAISE EXCEPTION 'Maximum 3 pinned messages per channel';
  END IF;

  -- Toggle pin
  UPDATE messages SET
    is_pinned = NOT is_pinned,
    pinned_at = CASE WHEN NOT is_pinned THEN now() ELSE NULL END,
    pinned_by = CASE WHEN NOT is_pinned THEN auth.uid() ELSE NULL END,
    updated_at = now()
  WHERE id = p_message_id
  RETURNING * INTO v_message;

  RETURN v_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get poll results
CREATE OR REPLACE FUNCTION public.get_poll_results(p_poll_id UUID)
RETURNS TABLE (
  option_id TEXT,
  vote_count BIGINT,
  voter_ids UUID[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    unnest(pv.option_ids) as option_id,
    COUNT(*) as vote_count,
    array_agg(pv.user_id) FILTER (WHERE mp.is_anonymous = false) as voter_ids
  FROM poll_votes pv
  JOIN message_polls mp ON mp.id = pv.poll_id
  WHERE pv.poll_id = p_poll_id
  GROUP BY unnest(pv.option_ids), mp.is_anonymous;
END;
$$ LANGUAGE plpgsql STABLE;

-- Clean up expired typing indicators (called periodically)
CREATE OR REPLACE FUNCTION public.cleanup_expired_typing()
RETURNS INT AS $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM typing_indicators WHERE expires_at < now();
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Update presence
CREATE OR REPLACE FUNCTION public.update_presence(
  p_channel_id UUID DEFAULT NULL,
  p_is_online BOOLEAN DEFAULT true,
  p_device_type TEXT DEFAULT NULL
)
RETURNS user_presence AS $$
DECLARE
  v_presence user_presence;
BEGIN
  INSERT INTO user_presence (user_id, channel_id, is_online, device_type, last_seen_at, updated_at)
  VALUES (auth.uid(), p_channel_id, p_is_online, p_device_type, now(), now())
  ON CONFLICT (user_id) DO UPDATE SET
    channel_id = COALESCE(p_channel_id, user_presence.channel_id),
    is_online = p_is_online,
    device_type = COALESCE(p_device_type, user_presence.device_type),
    last_seen_at = CASE WHEN p_is_online THEN now() ELSE user_presence.last_seen_at END,
    updated_at = now()
  RETURNING * INTO v_presence;

  RETURN v_presence;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
