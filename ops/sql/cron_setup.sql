-- ============================================================
-- pg_cron + pg_net Schedule Setup for UNO A
-- ============================================================
--
-- Prerequisites:
--   1. Enable pg_cron and pg_net extensions in Supabase Dashboard
--      (Database > Extensions > search for "pg_cron" / "pg_net")
--   2. Store secrets in Vault:
--      SELECT vault.create_secret('https://<project-ref>.supabase.co/functions/v1', 'project_url');
--      SELECT vault.create_secret('<your-cron-secret>', 'cron_secret');
--
-- Run this SQL in the Supabase SQL Editor after enabling extensions.
-- ============================================================

-- 1. Verify extensions are enabled
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    RAISE EXCEPTION 'pg_cron extension is not enabled. Enable it in the Supabase Dashboard first.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    RAISE EXCEPTION 'pg_net extension is not enabled. Enable it in the Supabase Dashboard first.';
  END IF;
END $$;

-- 2. scheduled-dispatcher: runs every minute
-- Dispatches pending scheduled messages, celebrations, etc.
SELECT cron.schedule(
  'invoke-scheduled-dispatcher',    -- job name
  '* * * * *',                      -- every minute
  $$
  SELECT net.http_post(
    url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url') || '/scheduled-dispatcher',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'cron_secret')
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);

-- 3. refresh-fallback-quotas: runs daily at 03:00 UTC (12:00 KST)
-- Resets daily reply quotas for users who didn't get a real-time reset
SELECT cron.schedule(
  'invoke-refresh-fallback-quotas', -- job name
  '0 3 * * *',                     -- daily at 03:00 UTC
  $$
  SELECT net.http_post(
    url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url') || '/refresh-fallback-quotas',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'cron_secret')
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);

-- ============================================================
-- Verification queries (run after setup)
-- ============================================================

-- Check registered jobs
-- SELECT jobid, schedule, command, nodename FROM cron.job;

-- Check recent execution history
-- SELECT jobid, runid, job_pid, status, return_message,
--        start_time, end_time
-- FROM cron.job_run_details
-- ORDER BY end_time DESC
-- LIMIT 20;

-- ============================================================
-- Cleanup (if needed)
-- ============================================================
-- SELECT cron.unschedule('invoke-scheduled-dispatcher');
-- SELECT cron.unschedule('invoke-refresh-fallback-quotas');
