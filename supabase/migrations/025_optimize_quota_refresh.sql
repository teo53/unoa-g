-- ============================================
-- UNO A - Optimize Quota Refresh Trigger (N+1 Fix)
-- Version: 1.0.0
-- ============================================
--
-- Problem: The original refresh_reply_quotas() function uses a FOR LOOP
-- to update quotas one by one, causing N+1 queries for N subscribers.
--
-- Solution: Use a single batch INSERT...ON CONFLICT statement to update
-- all subscriber quotas in one query.
-- ============================================

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_broadcast_sent ON messages;

-- Create optimized function
CREATE OR REPLACE FUNCTION refresh_reply_quotas()
RETURNS TRIGGER AS $$
DECLARE
  policy JSONB;
  default_tokens INTEGER;
BEGIN
  -- Only process broadcast messages from artists
  IF NEW.delivery_scope = 'broadcast' AND NEW.sender_type = 'artist' THEN

    -- Get token policy
    SELECT value INTO policy FROM policy_config WHERE key = 'token_rules' AND is_active = true;
    default_tokens := COALESCE((policy->>'default_tokens')::INTEGER, 3);

    -- Batch update/insert all subscriber quotas in a single query
    INSERT INTO reply_quota (
      user_id,
      channel_id,
      tokens_available,
      tokens_used,
      last_broadcast_id,
      last_broadcast_at,
      fallback_available,
      created_at,
      updated_at
    )
    SELECT
      sav.user_id,
      NEW.channel_id,
      -- Calculate final tokens: (default + age_bonus) * tier_multiplier
      FLOOR(
        (
          default_tokens +
          CASE
            WHEN sav.days_subscribed >= 14 THEN 2
            WHEN sav.days_subscribed >= 7 THEN 1
            ELSE 0
          END
        ) * COALESCE((policy->'tier_multipliers'->>sav.tier)::NUMERIC, 1.0)
      )::INTEGER,
      0, -- tokens_used reset
      NEW.id,
      NEW.created_at,
      false, -- fallback_available reset
      now(),
      now()
    FROM subscription_age_view sav
    WHERE sav.channel_id = NEW.channel_id
      AND sav.is_active = true
    ON CONFLICT (user_id, channel_id) DO UPDATE SET
      tokens_available = EXCLUDED.tokens_available,
      tokens_used = 0,
      last_broadcast_id = EXCLUDED.last_broadcast_id,
      last_broadcast_at = EXCLUDED.last_broadcast_at,
      fallback_available = false,
      updated_at = now();

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER on_broadcast_sent
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION refresh_reply_quotas();

-- Add comment for documentation
COMMENT ON FUNCTION refresh_reply_quotas() IS
'Refreshes reply quotas for all subscribers when an artist sends a broadcast.
Optimized to use batch INSERT...ON CONFLICT instead of row-by-row FOR LOOP.
Token calculation: (default_tokens + age_bonus) * tier_multiplier';

-- ============================================
-- Also optimize create_broadcast_delivery for consistency
-- ============================================

-- Already using batch INSERT, but let's add an index for better performance
CREATE INDEX IF NOT EXISTS idx_subscriptions_channel_active
  ON subscriptions(channel_id)
  WHERE is_active = true;

-- Add index on message_delivery for faster lookups
CREATE INDEX IF NOT EXISTS idx_message_delivery_message_user
  ON message_delivery(message_id, user_id);
