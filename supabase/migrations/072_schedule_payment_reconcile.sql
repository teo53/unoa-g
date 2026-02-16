-- =====================================================
-- Migration: 072_schedule_payment_reconcile.sql
-- WI-2A-3: Schedule payment-reconcile Edge Function
-- Purpose: pg_cron + pg_net to call payment-reconcile
--          every 30 minutes, closing pending purchase gaps.
-- Prerequisite: pg_cron and pg_net extensions enabled
--               (Supabase enables these by default)
-- =====================================================

-- Schedule the reconcile job (every 30 minutes)
-- Uses pg_net to HTTP POST to the Edge Function with service_role auth.
-- service_role_key should be stored in Vault for production;
-- here we read from app.settings which can be set via Dashboard > Settings.
SELECT cron.schedule(
  'payment-reconcile-job',
  '*/30 * * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/payment-reconcile',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

COMMENT ON COLUMN cron.job.jobname IS 'payment-reconcile-job: Runs every 30m to close pending purchase gaps via TossPayments status query.';
