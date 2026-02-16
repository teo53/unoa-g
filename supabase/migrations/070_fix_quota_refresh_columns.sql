-- =====================================================
-- Migration: 070_fix_quota_refresh_columns.sql
-- WI-1C: Patch async quota functions to use correct columns
-- Purpose: Fix process_quota_refresh_job() and reset_daily_quotas()
--          which still reference phantom columns from 013.
-- Note: refresh_reply_quotas() was already fixed by migration 025.
-- =====================================================

-- 1) Fix process_quota_refresh_job: remaining_replies/period_* → tokens_*
CREATE OR REPLACE FUNCTION public.process_quota_refresh_job(p_job_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job RECORD;
  v_channel_id UUID;
  v_quota_limit INT;
  v_processed_count INT;
  v_batch_size INT := 5000;
  v_offset INT := 0;
BEGIN
  -- Get and lock the job
  SELECT * INTO v_job
  FROM background_jobs
  WHERE id = p_job_id AND status = 'pending'
  FOR UPDATE SKIP LOCKED;

  IF v_job IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Job not found or already processed');
  END IF;

  -- Mark as processing
  UPDATE background_jobs
  SET status = 'processing', started_at = now(), attempts = attempts + 1
  WHERE id = p_job_id;

  -- Extract payload
  v_channel_id := (v_job.payload->>'channel_id')::UUID;
  v_quota_limit := (v_job.payload->>'quota_limit')::INT;
  v_processed_count := 0;

  -- Process in batches (FIXED: use tokens_available/tokens_used)
  LOOP
    WITH batch AS (
      SELECT s.user_id
      FROM subscriptions s
      WHERE s.channel_id = v_channel_id
        AND s.is_active = true
      ORDER BY s.user_id
      OFFSET v_offset
      LIMIT v_batch_size
    )
    INSERT INTO reply_quota (user_id, channel_id, tokens_available, tokens_used)
    SELECT
      b.user_id,
      v_channel_id,
      v_quota_limit,
      0
    FROM batch b
    ON CONFLICT (user_id, channel_id) DO UPDATE SET
      tokens_available = v_quota_limit,
      tokens_used = 0,
      updated_at = now();

    GET DIAGNOSTICS v_processed_count = ROW_COUNT;

    -- Exit if no more rows
    EXIT WHEN v_processed_count < v_batch_size;

    v_offset := v_offset + v_batch_size;

    -- Yield to other processes periodically
    PERFORM pg_sleep(0.01);
  END LOOP;

  -- Mark as completed
  UPDATE background_jobs
  SET
    status = 'completed',
    completed_at = now(),
    payload = v_job.payload || jsonb_build_object('processed_count', v_offset + v_processed_count)
  WHERE id = p_job_id;

  RETURN jsonb_build_object(
    'success', true,
    'processed_count', v_offset + v_processed_count
  );

EXCEPTION WHEN OTHERS THEN
  -- Mark as failed
  UPDATE background_jobs
  SET status = 'failed', error_message = SQLERRM
  WHERE id = p_job_id;

  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- 2) Fix reset_daily_quotas: remaining_replies/period_* → tokens_*
CREATE OR REPLACE FUNCTION public.reset_daily_quotas()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated_count INT;
BEGIN
  -- Reset quotas: restore tokens_available, zero tokens_used
  UPDATE reply_quota rq
  SET
    tokens_available = COALESCE(cs.fan_daily_limit, 3),
    tokens_used = 0,
    updated_at = now()
  FROM creator_settings cs
  JOIN creator_profiles cp ON cp.user_id = cs.creator_id
  WHERE rq.channel_id = cp.channel_id;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;

  RETURN jsonb_build_object(
    'success', true,
    'updated_count', v_updated_count,
    'reset_date', CURRENT_DATE
  );
END;
$$;

-- Re-grant (in case CREATE OR REPLACE resets grants)
GRANT EXECUTE ON FUNCTION public.process_quota_refresh_job TO service_role;
GRANT EXECUTE ON FUNCTION public.reset_daily_quotas TO service_role;

COMMENT ON FUNCTION public.process_quota_refresh_job IS
'Processes a queued quota refresh job in batches of 5000.
Fixed in 070: uses tokens_available/tokens_used instead of phantom remaining_replies/period_* columns.';

COMMENT ON FUNCTION public.reset_daily_quotas IS
'Resets all quotas daily: restores tokens_available from creator_settings, zeros tokens_used.
Fixed in 070: uses tokens_available/tokens_used instead of phantom remaining_replies/period_* columns.';
