-- =====================================================
-- Migration 050: Rate Limit Counters
-- Purpose: DB-based rate limiting for Edge Functions
-- Used by: ai-reply-suggest, ai-poll-suggest, payment-checkout
-- =====================================================

-- Rate limit counter table
CREATE TABLE IF NOT EXISTS public.rate_limit_counters (
  key TEXT NOT NULL,
  window_start TIMESTAMPTZ NOT NULL,
  counter INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (key, window_start)
);

-- Index for cleanup of expired windows
CREATE INDEX IF NOT EXISTS idx_rate_limit_window
  ON public.rate_limit_counters(window_start);

-- RLS: service_role only (no user access)
ALTER TABLE public.rate_limit_counters ENABLE ROW LEVEL SECURITY;

-- Deny all user-level access
CREATE POLICY rate_limit_deny_all ON public.rate_limit_counters
  FOR ALL USING (false);

-- Atomic check-and-increment function
-- Returns: allowed (boolean), current_count, window_start
CREATE OR REPLACE FUNCTION public.check_and_increment_rate_limit(
  p_key TEXT,
  p_limit INTEGER,
  p_window_seconds INTEGER
)
RETURNS TABLE(allowed BOOLEAN, current_count INTEGER, window_start TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_window_start TIMESTAMPTZ;
  v_current_count INTEGER;
BEGIN
  -- Calculate window start based on epoch flooring
  v_window_start := to_timestamp(
    floor(extract(epoch FROM now()) / p_window_seconds) * p_window_seconds
  );

  -- Atomic upsert: insert or increment counter
  INSERT INTO rate_limit_counters (key, window_start, counter)
  VALUES (p_key, v_window_start, 1)
  ON CONFLICT (key, window_start)
  DO UPDATE SET counter = rate_limit_counters.counter + 1
  WHERE rate_limit_counters.counter < p_limit
  RETURNING rate_limit_counters.counter INTO v_current_count;

  -- If no row was returned, we hit the limit
  IF v_current_count IS NULL THEN
    -- Get the current count (it's at the limit)
    SELECT rc.counter INTO v_current_count
    FROM rate_limit_counters rc
    WHERE rc.key = p_key AND rc.window_start = v_window_start;

    RETURN QUERY SELECT false, COALESCE(v_current_count, p_limit), v_window_start;
  ELSE
    RETURN QUERY SELECT true, v_current_count, v_window_start;
  END IF;
END;
$$;

-- Cleanup function for expired rate limit entries (call from cron)
CREATE OR REPLACE FUNCTION public.cleanup_rate_limit_counters()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM rate_limit_counters
  WHERE window_start < now() - interval '2 days';
END;
$$;
