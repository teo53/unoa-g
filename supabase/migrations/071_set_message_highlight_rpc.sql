-- =====================================================
-- Migration: 071_set_message_highlight_rpc.sql
-- WI-3A: set_message_highlight RPC for creators
-- Purpose: Allow channel creators to highlight/unhighlight
--          messages in their channel. Separate from pin_message
--          which is a different feature (announcements).
-- Rule #7: auth.uid() used internally, no user_id parameter
-- =====================================================

CREATE OR REPLACE FUNCTION set_message_highlight(
  p_message_id UUID,
  p_is_highlighted BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_message RECORD;
  v_channel RECORD;
BEGIN
  -- Extract authenticated user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Get the message
  SELECT id, channel_id, is_highlighted
  INTO v_message
  FROM messages
  WHERE id = p_message_id;

  IF v_message IS NULL THEN
    RAISE EXCEPTION 'Message not found';
  END IF;

  -- Verify caller is the channel creator
  SELECT id, creator_id
  INTO v_channel
  FROM channels
  WHERE id = v_message.channel_id;

  IF v_channel IS NULL OR v_channel.creator_id != v_user_id THEN
    RAISE EXCEPTION 'Only channel creator can highlight messages';
  END IF;

  -- Update highlight status
  UPDATE messages
  SET is_highlighted = p_is_highlighted,
      updated_at = now()
  WHERE id = p_message_id;

  RETURN jsonb_build_object(
    'success', true,
    'message_id', p_message_id,
    'is_highlighted', p_is_highlighted
  );
END;
$$;

GRANT EXECUTE ON FUNCTION set_message_highlight TO authenticated;

COMMENT ON FUNCTION set_message_highlight IS
'Allows channel creator to highlight/unhighlight messages.
Uses auth.uid() internally (Rule #7). Separate from pin_message.';
