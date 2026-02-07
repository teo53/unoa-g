-- ============================================
-- UNO A - Fix get_celebration_queue return fields
-- Version: 1.0.0
-- ============================================
-- Adds channel_id, due_date, created_at, sent_at to the returned JSON
-- so CelebrationEvent.fromJson() can parse all required fields.

CREATE OR REPLACE FUNCTION get_celebration_queue(p_channel_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_kst_date DATE;
  v_result JSONB;
BEGIN
  -- Verify creator owns channel
  IF NOT EXISTS (
    SELECT 1 FROM channels WHERE id = p_channel_id AND artist_id = auth.uid()
  ) THEN
    RETURN jsonb_build_object('error', 'Not channel owner');
  END IF;

  -- Get today's KST date
  v_kst_date := (now() AT TIME ZONE 'Asia/Seoul')::date;

  -- Generate today's celebrations (idempotent)
  PERFORM generate_daily_celebrations(p_channel_id);

  SELECT jsonb_build_object(
    'kst_date', v_kst_date,
    'birthday_count', (
      SELECT COUNT(*) FROM celebration_events
      WHERE channel_id = p_channel_id AND due_date = v_kst_date
        AND event_type = 'birthday' AND status = 'pending'
    ),
    'milestone_count', (
      SELECT COUNT(*) FROM celebration_events
      WHERE channel_id = p_channel_id AND due_date = v_kst_date
        AND event_type LIKE 'milestone_%' AND status = 'pending'
    ),
    'events', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'event_id', ce.id,
          'channel_id', ce.channel_id,
          'fan_celebration_id', ce.fan_celebration_id,
          'event_type', ce.event_type,
          'due_date', ce.due_date,
          'nickname', ce.payload->>'nickname',
          'day_count', ce.payload->'day_count',
          'tier', ce.payload->>'tier',
          'status', ce.status,
          'created_at', ce.created_at,
          'sent_at', ce.sent_at
        ) ORDER BY ce.event_type, (ce.payload->>'nickname')
      )
      FROM celebration_events ce
      WHERE ce.channel_id = p_channel_id
        AND ce.due_date = v_kst_date
        AND ce.status = 'pending'
    ), '[]'::jsonb)
  ) INTO v_result;

  RETURN v_result;
END;
$$;
