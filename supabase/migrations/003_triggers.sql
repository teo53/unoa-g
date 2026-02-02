-- ============================================
-- UNO A - Database Triggers & Functions
-- Version: 1.0.0
-- ============================================

-- ============================================
-- HELPER: Get config value
-- ============================================
CREATE OR REPLACE FUNCTION public.get_policy_config(p_key TEXT)
RETURNS JSONB AS $$
  SELECT value FROM public.policy_config WHERE key = p_key AND is_active = true;
$$ LANGUAGE sql STABLE;

-- ============================================
-- TRIGGER: Refresh quotas when artist sends broadcast
-- ============================================
CREATE OR REPLACE FUNCTION refresh_reply_quotas()
RETURNS TRIGGER AS $$
DECLARE
  policy JSONB;
  default_tokens INTEGER;
  sub RECORD;
  bonus_tokens INTEGER;
  tier_multiplier NUMERIC;
  final_tokens INTEGER;
BEGIN
  -- Only process broadcast messages from artists
  IF NEW.delivery_scope = 'broadcast' AND NEW.sender_type = 'artist' THEN

    -- Get token policy
    SELECT value INTO policy FROM policy_config WHERE key = 'token_rules' AND is_active = true;
    default_tokens := COALESCE((policy->>'default_tokens')::INTEGER, 3);

    -- Update quotas for all active subscribers
    FOR sub IN
      SELECT sav.user_id, sav.days_subscribed, sav.tier
      FROM subscription_age_view sav
      WHERE sav.channel_id = NEW.channel_id AND sav.is_active = true
    LOOP
      -- Calculate age bonus
      bonus_tokens := 0;
      IF sub.days_subscribed >= 14 THEN
        bonus_tokens := 2;
      ELSIF sub.days_subscribed >= 7 THEN
        bonus_tokens := 1;
      END IF;

      -- Get tier multiplier
      tier_multiplier := COALESCE((policy->'tier_multipliers'->>sub.tier)::NUMERIC, 1.0);

      -- Calculate final tokens
      final_tokens := FLOOR((default_tokens + bonus_tokens) * tier_multiplier);

      -- Upsert quota record
      INSERT INTO reply_quota (
        user_id, channel_id, tokens_available, tokens_used,
        last_broadcast_id, last_broadcast_at, fallback_available
      )
      VALUES (
        sub.user_id, NEW.channel_id, final_tokens, 0,
        NEW.id, NEW.created_at, false
      )
      ON CONFLICT (user_id, channel_id) DO UPDATE SET
        tokens_available = final_tokens,
        tokens_used = 0,
        last_broadcast_id = NEW.id,
        last_broadcast_at = NEW.created_at,
        fallback_available = false,
        updated_at = now();
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_broadcast_sent
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION refresh_reply_quotas();

-- ============================================
-- HELPER: Get character limit based on subscription age
-- ============================================
CREATE OR REPLACE FUNCTION get_char_limit_for_user(p_user_id UUID, p_channel_id UUID)
RETURNS INTEGER AS $$
DECLARE
  days_subscribed INTEGER;
  char_limits JSONB;
  progression JSONB;
  item JSONB;
  result_limit INTEGER := 50; -- default
BEGIN
  -- Get subscription age
  SELECT EXTRACT(DAY FROM (now() - started_at))::INTEGER
  INTO days_subscribed
  FROM subscriptions
  WHERE user_id = p_user_id AND channel_id = p_channel_id AND is_active = true;

  IF days_subscribed IS NULL THEN
    days_subscribed := 0;
  END IF;

  -- Get character limits config
  SELECT value INTO char_limits FROM policy_config WHERE key = 'character_limits' AND is_active = true;

  IF char_limits IS NULL THEN
    RETURN 50; -- default fallback
  END IF;

  progression := char_limits->'progression';

  -- Find the appropriate limit based on days subscribed
  -- progression is ordered, so we find the highest min_days <= days_subscribed
  FOR item IN SELECT * FROM jsonb_array_elements(progression)
  LOOP
    IF (item->>'min_days')::INTEGER <= days_subscribed THEN
      result_limit := (item->>'max_chars')::INTEGER;
    END IF;
  END LOOP;

  RETURN result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- TRIGGER: Validate and decrement quota on fan reply
-- ============================================
CREATE OR REPLACE FUNCTION validate_and_decrement_quota()
RETURNS TRIGGER AS $$
DECLARE
  current_quota RECORD;
  max_reply_length INTEGER;
BEGIN
  -- Only process fan's direct replies (NOT donation messages)
  IF NEW.delivery_scope = 'direct_reply' AND NEW.sender_type = 'fan' THEN

    -- Check message length based on subscription age (Bubble-style)
    max_reply_length := get_char_limit_for_user(NEW.sender_id, NEW.channel_id);

    IF length(COALESCE(NEW.content, '')) > max_reply_length THEN
      RAISE EXCEPTION 'Message too long. Maximum % characters allowed for your subscription age.', max_reply_length;
    END IF;

    -- Get quota with lock
    SELECT * INTO current_quota
    FROM reply_quota
    WHERE user_id = NEW.sender_id AND channel_id = NEW.channel_id
    FOR UPDATE;

    IF current_quota IS NULL THEN
      RAISE EXCEPTION 'No reply quota found. Please wait for artist broadcast.';
    END IF;

    -- Check if using regular tokens or fallback
    IF current_quota.tokens_available > 0 THEN
      UPDATE reply_quota SET
        tokens_available = tokens_available - 1,
        tokens_used = tokens_used + 1,
        last_reply_at = now(),
        updated_at = now()
      WHERE id = current_quota.id;
    ELSIF current_quota.fallback_available THEN
      UPDATE reply_quota SET
        fallback_available = false,
        fallback_used_at = now(),
        last_reply_at = now(),
        updated_at = now()
      WHERE id = current_quota.id;
    ELSE
      RAISE EXCEPTION 'No reply tokens available. Please wait for next artist broadcast.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_reply_validate_quota
  BEFORE INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION validate_and_decrement_quota();

-- ============================================
-- TRIGGER: Validate donation message length
-- ============================================
CREATE OR REPLACE FUNCTION validate_donation_message()
RETURNS TRIGGER AS $$
DECLARE
  msg_limits JSONB;
  max_donation_msg_length INTEGER;
BEGIN
  -- Only process donation messages
  IF NEW.delivery_scope = 'donation_message' AND NEW.sender_type = 'fan' THEN

    SELECT value INTO msg_limits FROM policy_config WHERE key = 'message_limits' AND is_active = true;
    max_donation_msg_length := COALESCE((msg_limits->>'max_donation_message_length')::INTEGER, 100);

    IF length(COALESCE(NEW.content, '')) > max_donation_msg_length THEN
      RAISE EXCEPTION 'Donation message too long. Maximum % characters allowed.', max_donation_msg_length;
    END IF;

    -- Verify donation exists
    IF NEW.donation_id IS NULL THEN
      RAISE EXCEPTION 'Donation ID required for donation messages.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_donation_message_validate
  BEFORE INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION validate_donation_message();

-- ============================================
-- TRIGGER: Validate artist donation reply
-- ============================================
CREATE OR REPLACE FUNCTION validate_donation_reply()
RETURNS TRIGGER AS $$
DECLARE
  reply_rules JSONB;
  max_reply_length INTEGER;
  reply_window_hours INTEGER;
  original_message RECORD;
BEGIN
  -- Only process donation replies from artists
  IF NEW.delivery_scope = 'donation_reply' AND NEW.sender_type = 'artist' THEN

    -- Get donation reply rules
    SELECT value INTO reply_rules FROM policy_config WHERE key = 'donation_reply_rules' AND is_active = true;
    max_reply_length := COALESCE((reply_rules->>'max_reply_length')::INTEGER, 500);
    reply_window_hours := COALESCE((reply_rules->>'reply_window_hours')::INTEGER, 168); -- 7 days default

    -- Check reply length
    IF length(COALESCE(NEW.content, '')) > max_reply_length THEN
      RAISE EXCEPTION 'Reply too long. Maximum % characters allowed.', max_reply_length;
    END IF;

    -- Verify replying to a donation message
    SELECT * INTO original_message
    FROM messages
    WHERE id = NEW.reply_to_message_id;

    IF original_message IS NULL THEN
      RAISE EXCEPTION 'Original message not found.';
    END IF;

    IF original_message.delivery_scope != 'donation_message' THEN
      RAISE EXCEPTION 'Artist can only reply to donation messages.';
    END IF;

    -- Check reply window
    IF original_message.created_at < now() - (reply_window_hours || ' hours')::INTERVAL THEN
      RAISE EXCEPTION 'Reply window has expired. Can only reply within % hours.', reply_window_hours;
    END IF;

    -- Set target_user_id to the original sender
    NEW.target_user_id := original_message.sender_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_donation_reply_validate
  BEFORE INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION validate_donation_reply();

-- ============================================
-- TRIGGER: Create message_delivery records for broadcasts
-- ============================================
CREATE OR REPLACE FUNCTION create_broadcast_delivery()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.delivery_scope = 'broadcast' THEN
    INSERT INTO message_delivery (message_id, user_id)
    SELECT NEW.id, s.user_id
    FROM subscriptions s
    WHERE s.channel_id = NEW.channel_id AND s.is_active = true;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_broadcast_create_delivery
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION create_broadcast_delivery();

-- ============================================
-- FUNCTION: Enable fallback quotas (called by edge function)
-- ============================================
CREATE OR REPLACE FUNCTION enable_fallback_quotas(cutoff_date TIMESTAMPTZ)
RETURNS INTEGER AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  UPDATE reply_quota
  SET
    fallback_available = true,
    updated_at = now()
  WHERE
    tokens_available = 0
    AND fallback_available = false
    AND (last_broadcast_at IS NULL OR last_broadcast_at < cutoff_date)
    AND EXISTS (
      SELECT 1 FROM subscriptions s
      WHERE s.user_id = reply_quota.user_id
        AND s.channel_id = reply_quota.channel_id
        AND s.is_active = true
    );

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Get user's chat thread with an artist
-- ============================================
CREATE OR REPLACE FUNCTION get_user_chat_thread(
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
  FROM messages m
  LEFT JOIN message_delivery md ON m.id = md.message_id AND md.user_id = auth.uid()
  WHERE m.channel_id = p_channel_id
    AND m.deleted_at IS NULL
    AND (
      -- Broadcasts
      (m.delivery_scope = 'broadcast')
      OR
      -- User's own replies/donations
      (m.delivery_scope IN ('direct_reply', 'donation_message') AND m.sender_id = auth.uid())
      OR
      -- Artist replies to user's donations
      (m.delivery_scope = 'donation_reply' AND m.target_user_id = auth.uid())
    )
    AND (p_before_id IS NULL OR m.created_at < (SELECT created_at FROM messages WHERE id = p_before_id))
  ORDER BY m.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Get artist inbox (fan messages)
-- ============================================
CREATE OR REPLACE FUNCTION get_artist_inbox(
  p_channel_id UUID,
  p_filter_type TEXT DEFAULT 'all', -- 'all', 'donation', 'regular', 'highlighted'
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
      SELECT 1 FROM messages r
      WHERE r.reply_to_message_id = m.id
        AND r.sender_type = 'artist'
    ) as has_artist_reply
  FROM messages m
  LEFT JOIN auth.users p ON m.sender_id = p.id
  LEFT JOIN subscriptions s ON s.user_id = m.sender_id AND s.channel_id = m.channel_id
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Get wallet summary with quota info
-- ============================================
CREATE OR REPLACE FUNCTION get_chat_quota_summary(p_user_id UUID, p_channel_id UUID)
RETURNS TABLE (
  tokens_available INTEGER,
  tokens_used INTEGER,
  fallback_available BOOLEAN,
  last_broadcast_at TIMESTAMPTZ,
  can_reply BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(q.tokens_available, 0),
    COALESCE(q.tokens_used, 0),
    COALESCE(q.fallback_available, false),
    q.last_broadcast_at,
    (COALESCE(q.tokens_available, 0) > 0 OR COALESCE(q.fallback_available, false)) as can_reply
  FROM reply_quota q
  WHERE q.user_id = p_user_id AND q.channel_id = p_channel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
