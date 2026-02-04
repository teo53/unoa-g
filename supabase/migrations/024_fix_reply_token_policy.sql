-- ============================================
-- UNO A - Fix Reply Token Validation in RLS Policy
-- Version: 1.0.0
-- ============================================
--
-- Problem: The original "Subscribers can insert replies" policy only checked
-- for active subscription, but token validation was deferred to a trigger
-- that doesn't exist or isn't enforced at the DB level.
--
-- Solution: Add token check directly in the RLS policy to ensure replies
-- can only be inserted when the user has available tokens or fallback.
-- ============================================

-- Drop existing policy
DROP POLICY IF EXISTS "Subscribers can insert replies" ON messages;

-- Create new policy with token validation
CREATE POLICY "Subscribers can insert replies"
  ON messages FOR INSERT
  WITH CHECK (
    sender_type = 'fan'
    AND delivery_scope = 'direct_reply'
    AND sender_id = auth.uid()
    -- Check active subscription
    AND EXISTS (
      SELECT 1 FROM subscriptions
      WHERE channel_id = messages.channel_id
        AND user_id = auth.uid()
        AND is_active = true
    )
    -- Check token availability (tokens_available > 0 OR fallback_available = true)
    AND EXISTS (
      SELECT 1 FROM reply_quota
      WHERE channel_id = messages.channel_id
        AND user_id = auth.uid()
        AND (tokens_available > 0 OR fallback_available = true)
    )
  );

-- Create a trigger function to consume token after successful message insert
CREATE OR REPLACE FUNCTION consume_reply_token()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process fan direct replies
  IF NEW.sender_type = 'fan' AND NEW.delivery_scope = 'direct_reply' THEN
    -- First try to use regular tokens
    UPDATE reply_quota
    SET
      tokens_available = GREATEST(0, tokens_available - 1),
      tokens_used = tokens_used + 1,
      updated_at = now()
    WHERE channel_id = NEW.channel_id
      AND user_id = NEW.sender_id
      AND tokens_available > 0;

    -- If no regular tokens were consumed, use fallback
    IF NOT FOUND THEN
      UPDATE reply_quota
      SET
        fallback_available = false,
        tokens_used = tokens_used + 1,
        updated_at = now()
      WHERE channel_id = NEW.channel_id
        AND user_id = NEW.sender_id
        AND fallback_available = true;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_consume_reply_token ON messages;

-- Create trigger
CREATE TRIGGER trigger_consume_reply_token
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION consume_reply_token();

-- Add comment for documentation
COMMENT ON POLICY "Subscribers can insert replies" ON messages IS
  'Fans can insert direct replies only if they have an active subscription AND available reply tokens (regular or fallback). Token consumption is handled by the trigger_consume_reply_token trigger.';
