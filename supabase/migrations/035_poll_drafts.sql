-- ============================================
-- UNO A - Poll Drafts & Vote Update Policy
-- Version: 1.0.0
-- ============================================

-- 1. AI-generated poll candidate drafts
CREATE TABLE IF NOT EXISTS public.poll_drafts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  correlation_id TEXT NOT NULL,

  -- AI-generated content
  category TEXT NOT NULL CHECK (category IN (
    'preference_vs', 'content_choice', 'light_tmi',
    'schedule_choice', 'mini_mission'
  )),
  question TEXT NOT NULL,
  options JSONB NOT NULL,  -- [{id: "opt_a", text: "Option A"}, ...]

  -- Status
  status TEXT NOT NULL DEFAULT 'suggested'
    CHECK (status IN ('suggested', 'selected', 'sent', 'expired', 'rejected')),

  -- Safety
  safety_filtered BOOLEAN DEFAULT false,
  safety_reason TEXT,

  -- Link to sent poll
  poll_id UUID REFERENCES message_polls(id),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  selected_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ DEFAULT now() + INTERVAL '24 hours'
);

CREATE INDEX IF NOT EXISTS idx_poll_drafts_channel
  ON poll_drafts(channel_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_poll_drafts_creator
  ON poll_drafts(creator_id);

ALTER TABLE poll_drafts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creator can view own poll drafts"
  ON poll_drafts FOR SELECT
  USING (creator_id = auth.uid());

CREATE POLICY "Creator can insert own poll drafts"
  ON poll_drafts FOR INSERT
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Creator can update own poll drafts"
  ON poll_drafts FOR UPDATE
  USING (creator_id = auth.uid());

-- 2. Missing UPDATE policy for poll_votes (allows vote change before poll ends)
CREATE POLICY "Users can update own vote before poll ends"
  ON poll_votes FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM message_polls mp
      WHERE mp.id = poll_votes.poll_id
      AND (mp.ends_at IS NULL OR mp.ends_at > now())
    )
  );

-- 3. Rate limiting function (max 5 polls per channel per KST day)
CREATE OR REPLACE FUNCTION check_poll_rate_limit(p_channel_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  v_count INT;
  v_kst_today DATE;
BEGIN
  v_kst_today := (now() AT TIME ZONE 'Asia/Seoul')::date;
  SELECT COUNT(*) INTO v_count
  FROM poll_drafts
  WHERE channel_id = p_channel_id
    AND status = 'sent'
    AND (sent_at AT TIME ZONE 'Asia/Seoul')::date = v_kst_today;
  RETURN v_count < 5;
END;
$$;

-- 4. Create poll message helper (inserts message + message_polls atomically)
CREATE OR REPLACE FUNCTION create_poll_message(
  p_channel_id UUID,
  p_question TEXT,
  p_options JSONB,
  p_allow_multiple BOOLEAN DEFAULT false,
  p_ends_at TIMESTAMPTZ DEFAULT NULL,
  p_is_anonymous BOOLEAN DEFAULT false,
  p_comment TEXT DEFAULT NULL,
  p_draft_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_message_id UUID;
  v_poll_id UUID;
  v_content TEXT;
BEGIN
  -- Verify creator owns channel
  IF NOT EXISTS (
    SELECT 1 FROM channels WHERE id = p_channel_id AND artist_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not channel owner';
  END IF;

  -- Check rate limit
  IF NOT check_poll_rate_limit(p_channel_id) THEN
    RAISE EXCEPTION 'Daily poll limit reached (max 5)';
  END IF;

  -- Build content: question + optional comment
  v_content := p_question;
  IF p_comment IS NOT NULL AND p_comment != '' THEN
    v_content := v_content || E'\n\n' || p_comment;
  END IF;

  -- Insert message
  INSERT INTO messages (
    channel_id, sender_id, sender_type,
    delivery_scope, content, message_type
  ) VALUES (
    p_channel_id, auth.uid(), 'artist',
    'broadcast', v_content, 'poll'
  ) RETURNING id INTO v_message_id;

  -- Insert poll
  INSERT INTO message_polls (
    message_id, question, options,
    allow_multiple, ends_at, is_anonymous
  ) VALUES (
    v_message_id, p_question, p_options,
    p_allow_multiple,
    COALESCE(p_ends_at, now() + INTERVAL '24 hours'),
    p_is_anonymous
  ) RETURNING id INTO v_poll_id;

  -- Update draft if provided
  IF p_draft_id IS NOT NULL THEN
    UPDATE poll_drafts
    SET status = 'sent', sent_at = now(), poll_id = v_poll_id
    WHERE id = p_draft_id AND creator_id = auth.uid();
  END IF;

  RETURN jsonb_build_object(
    'message_id', v_message_id,
    'poll_id', v_poll_id
  );
END;
$$;
