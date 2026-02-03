-- =====================================================
-- Migration: 013_optimize_quota_refresh.sql
-- Purpose: Optimize the refresh_reply_quotas trigger
-- Description: Replaces FOR LOOP with bulk operations
--              for better performance with large channels
-- =====================================================

-- Drop existing function and recreate with optimized version
DROP FUNCTION IF EXISTS public.refresh_reply_quotas() CASCADE;

-- Create optimized version using bulk UPSERT
CREATE OR REPLACE FUNCTION public.refresh_reply_quotas()
RETURNS TRIGGER AS $$
DECLARE
  v_channel_id UUID;
  v_quota_limit INT;
  v_subscriber_count INT;
BEGIN
  -- Get channel ID from the trigger context
  -- This function is called on creator_settings update
  v_channel_id := (
    SELECT cp.channel_id
    FROM creator_profiles cp
    WHERE cp.user_id = NEW.creator_id
  );

  -- If no channel found, skip
  IF v_channel_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get the quota limit
  v_quota_limit := COALESCE(NEW.fan_daily_limit, 3);

  -- Get subscriber count for logging
  SELECT COUNT(*) INTO v_subscriber_count
  FROM subscriptions
  WHERE channel_id = v_channel_id AND is_active = true;

  -- For small channels (< 1000 subscribers), do synchronous update
  IF v_subscriber_count < 1000 THEN
    -- Bulk UPSERT for all active subscribers
    INSERT INTO reply_quota (user_id, channel_id, remaining_replies, period_start, period_end)
    SELECT
      s.user_id,
      v_channel_id,
      v_quota_limit,
      CURRENT_DATE,
      CURRENT_DATE + INTERVAL '1 day'
    FROM subscriptions s
    WHERE s.channel_id = v_channel_id
      AND s.is_active = true
    ON CONFLICT (user_id, channel_id) DO UPDATE SET
      remaining_replies = v_quota_limit,
      period_start = CURRENT_DATE,
      period_end = CURRENT_DATE + INTERVAL '1 day';

    RAISE NOTICE 'Quota refresh completed for % subscribers synchronously', v_subscriber_count;
  ELSE
    -- For large channels, queue for async processing
    -- Insert a job record that will be processed by a background worker
    INSERT INTO background_jobs (
      job_type,
      payload,
      status,
      scheduled_at
    ) VALUES (
      'refresh_channel_quotas',
      jsonb_build_object(
        'channel_id', v_channel_id,
        'quota_limit', v_quota_limit,
        'subscriber_count', v_subscriber_count
      ),
      'pending',
      now()
    );

    RAISE NOTICE 'Quota refresh queued for % subscribers (async)', v_subscriber_count;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_creator_settings_update ON creator_settings;
CREATE TRIGGER on_creator_settings_update
  AFTER UPDATE OF fan_daily_limit, room_type ON creator_settings
  FOR EACH ROW
  WHEN (OLD.fan_daily_limit IS DISTINCT FROM NEW.fan_daily_limit
        OR OLD.room_type IS DISTINCT FROM NEW.room_type)
  EXECUTE FUNCTION public.refresh_reply_quotas();

-- =====================================================
-- 2. BACKGROUND JOBS TABLE (for async processing)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.background_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  attempts INT DEFAULT 0,
  max_attempts INT DEFAULT 3,
  error_message TEXT,
  scheduled_at TIMESTAMPTZ DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for job processing
CREATE INDEX IF NOT EXISTS idx_background_jobs_status_scheduled
  ON background_jobs(status, scheduled_at)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_background_jobs_type_status
  ON background_jobs(job_type, status);

-- RLS for background_jobs (service role only)
ALTER TABLE background_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage jobs"
  ON background_jobs FOR ALL
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 3. ASYNC JOB PROCESSOR FUNCTION
-- =====================================================

-- Function to process queued quota refresh jobs
-- This would be called by a scheduled Edge Function
CREATE OR REPLACE FUNCTION public.process_quota_refresh_job(p_job_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
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

  -- Process in batches
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
    INSERT INTO reply_quota (user_id, channel_id, remaining_replies, period_start, period_end)
    SELECT
      b.user_id,
      v_channel_id,
      v_quota_limit,
      CURRENT_DATE,
      CURRENT_DATE + INTERVAL '1 day'
    FROM batch b
    ON CONFLICT (user_id, channel_id) DO UPDATE SET
      remaining_replies = v_quota_limit,
      period_start = CURRENT_DATE,
      period_end = CURRENT_DATE + INTERVAL '1 day';

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

-- =====================================================
-- 4. DAILY QUOTA RESET FUNCTION
-- =====================================================

-- Function to reset all quotas at midnight
-- Called by a scheduled Edge Function daily
CREATE OR REPLACE FUNCTION public.reset_daily_quotas()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated_count INT;
BEGIN
  -- Reset quotas where period has ended
  UPDATE reply_quota rq
  SET
    remaining_replies = cs.fan_daily_limit,
    period_start = CURRENT_DATE,
    period_end = CURRENT_DATE + INTERVAL '1 day'
  FROM creator_settings cs
  JOIN creator_profiles cp ON cp.user_id = cs.creator_id
  WHERE rq.channel_id = cp.channel_id
    AND rq.period_end <= CURRENT_DATE;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;

  RETURN jsonb_build_object(
    'success', true,
    'updated_count', v_updated_count,
    'reset_date', CURRENT_DATE
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.process_quota_refresh_job TO service_role;
GRANT EXECUTE ON FUNCTION public.reset_daily_quotas TO service_role;

COMMENT ON FUNCTION public.refresh_reply_quotas IS
'Optimized quota refresh that uses bulk UPSERT for small channels and async processing for large channels (1000+ subscribers).';

COMMENT ON FUNCTION public.process_quota_refresh_job IS
'Processes a queued quota refresh job in batches of 5000 to avoid long-running transactions.';

COMMENT ON FUNCTION public.reset_daily_quotas IS
'Resets all reply quotas daily. Should be called by a scheduled Edge Function at midnight KST.';
