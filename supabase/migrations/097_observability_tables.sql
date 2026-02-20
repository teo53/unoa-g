-- =====================================================
-- Migration: 073_observability_tables.sql
-- WI-OBS-1: T1-T4 Observability Infrastructure
-- Purpose: Tables for incident tracking (T2), long-running
--          job telemetry (T3), and middleware event counting
--          (T4). Also schedules cleanup cron jobs that
--          had functions but no schedule (050, 034).
-- Prerequisite: 050 (rate_limit_counters),
--               056 (ops_staff, is_ops_staff, ops_set_updated_at),
--               072 (pg_cron, pg_net extensions)
-- =====================================================

-- ─────────────────────────────────────────────
-- 1. ops_incidents — Incident lifecycle tracking (T2)
-- ─────────────────────────────────────────────
-- MTTR = AVG(mttr_minutes) WHERE severity = 'P0'
-- Ops staff open/close manually via SQL Editor.
CREATE TABLE IF NOT EXISTS public.ops_incidents (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT NOT NULL,
  severity      TEXT NOT NULL DEFAULT 'P2'
                CHECK (severity IN ('P0', 'P1', 'P2', 'P3')),
  status        TEXT NOT NULL DEFAULT 'open'
                CHECK (status IN ('open', 'mitigating', 'monitoring', 'closed')),
  trigger_type  TEXT NOT NULL DEFAULT 'manual'
                CHECK (trigger_type IN ('manual', 'alert', 'pg_cron', 'edge_fn')),
  -- Timeline
  open_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  mitigated_at  TIMESTAMPTZ,
  closed_at     TIMESTAMPTZ,
  -- Computed (stored for query performance)
  mttr_minutes  INT GENERATED ALWAYS AS (
    CASE WHEN closed_at IS NOT NULL
    THEN EXTRACT(EPOCH FROM (closed_at - open_at))::INT / 60
    ELSE NULL END
  ) STORED,
  -- Context
  affected_fn   TEXT,
  slack_thread  TEXT,
  notion_wi     TEXT,
  notes         TEXT,
  -- Audit
  opened_by     UUID REFERENCES auth.users(id),
  closed_by     UUID REFERENCES auth.users(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.ops_incidents ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_ops_incidents_status
  ON public.ops_incidents (status)
  WHERE status <> 'closed';

CREATE INDEX IF NOT EXISTS idx_ops_incidents_severity
  ON public.ops_incidents (severity, open_at DESC);

CREATE INDEX IF NOT EXISTS idx_ops_incidents_open_at
  ON public.ops_incidents (open_at DESC);

COMMENT ON TABLE public.ops_incidents IS
  'Incident lifecycle for MTTR calculation. SoT for T2 trigger.';
COMMENT ON COLUMN public.ops_incidents.mttr_minutes IS
  'Auto-computed: (closed_at - open_at) in minutes. NULL while open.';

-- ─────────────────────────────────────────────
-- 2. ops_jobs — Long-running job telemetry (T3)
-- ─────────────────────────────────────────────
-- Tracks scheduled/batch jobs. Written by Edge Functions.
-- Complements ai_draft_jobs (034) which tracks AI-specific jobs.
CREATE TABLE IF NOT EXISTS public.ops_jobs (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_name       TEXT NOT NULL,
  job_type       TEXT NOT NULL DEFAULT 'cron'
                 CHECK (job_type IN ('cron', 'batch', 'edge_fn', 'manual')),
  status         TEXT NOT NULL DEFAULT 'running'
                 CHECK (status IN ('running', 'success', 'failed', 'timeout')),
  -- Timing
  started_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at    TIMESTAMPTZ,
  duration_ms    INT GENERATED ALWAYS AS (
    CASE WHEN finished_at IS NOT NULL
    THEN EXTRACT(EPOCH FROM (finished_at - started_at))::INT * 1000
    ELSE NULL END
  ) STORED,
  -- Results
  records_processed INT DEFAULT 0,
  records_failed    INT DEFAULT 0,
  -- Error tracking
  error_code     TEXT,
  error_message  TEXT,
  -- Correlation
  correlation_id TEXT,
  triggered_by   TEXT,
  -- Auto-cleanup
  expires_at     TIMESTAMPTZ NOT NULL DEFAULT now() + INTERVAL '30 days'
);

ALTER TABLE public.ops_jobs ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_ops_jobs_name_started
  ON public.ops_jobs (job_name, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_ops_jobs_status
  ON public.ops_jobs (status)
  WHERE status = 'running';

CREATE INDEX IF NOT EXISTS idx_ops_jobs_expires
  ON public.ops_jobs (expires_at)
  WHERE expires_at IS NOT NULL;

COMMENT ON TABLE public.ops_jobs IS
  'Long-running job telemetry for T3 trigger. 30-day TTL.';

-- ─────────────────────────────────────────────
-- 3. ops_mw_events — Middleware event counting (T4)
-- ─────────────────────────────────────────────
-- Written by _shared/mw_metrics.ts on rate_limited,
-- schema_invalid, circuit_open, abuse_suspected, error_5xx,
-- slow_request events. 7-day rolling window.
CREATE TABLE IF NOT EXISTS public.ops_mw_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fn_name     TEXT NOT NULL,
  event_type  TEXT NOT NULL
              CHECK (event_type IN (
                'rate_limited',
                'schema_invalid',
                'circuit_open',
                'abuse_suspected',
                'error_5xx',
                'slow_request'
              )),
  -- Request context (no PII)
  status_code INT,
  latency_ms  INT,
  user_hash   TEXT,
  -- Auto-cleanup
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at  TIMESTAMPTZ NOT NULL DEFAULT now() + INTERVAL '7 days'
);

ALTER TABLE public.ops_mw_events ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_ops_mw_events_fn_type
  ON public.ops_mw_events (fn_name, event_type, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_ops_mw_events_recorded
  ON public.ops_mw_events (recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_ops_mw_events_expires
  ON public.ops_mw_events (expires_at);

COMMENT ON TABLE public.ops_mw_events IS
  'Middleware event stream for T4 trigger. 7-day rolling window. No PII stored.';

-- ─────────────────────────────────────────────
-- 4. RLS Policies (follows 056 pattern)
-- ─────────────────────────────────────────────

-- ops_incidents: ops_staff can read; operator+ can write; admin can delete
CREATE POLICY "ops_incidents_select" ON public.ops_incidents
  FOR SELECT USING (is_ops_staff());

CREATE POLICY "ops_incidents_insert" ON public.ops_incidents
  FOR INSERT WITH CHECK (is_ops_staff('operator'));

CREATE POLICY "ops_incidents_update" ON public.ops_incidents
  FOR UPDATE USING (is_ops_staff('operator'));

CREATE POLICY "ops_incidents_delete" ON public.ops_incidents
  FOR DELETE USING (is_ops_staff('admin'));

-- ops_jobs: ops_staff can read; service_role writes (no client writes)
CREATE POLICY "ops_jobs_select" ON public.ops_jobs
  FOR SELECT USING (is_ops_staff());

-- ops_mw_events: ops_staff can read; service_role writes (no client writes)
CREATE POLICY "ops_mw_events_select" ON public.ops_mw_events
  FOR SELECT USING (is_ops_staff());

-- ─────────────────────────────────────────────
-- 5. GRANTS (least privilege — follows 056 pattern)
-- ─────────────────────────────────────────────
REVOKE ALL ON ops_incidents FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ops_incidents TO authenticated;
GRANT INSERT ON ops_incidents TO service_role;

REVOKE ALL ON ops_jobs FROM authenticated;
GRANT SELECT ON ops_jobs TO authenticated;
GRANT INSERT, UPDATE ON ops_jobs TO service_role;

REVOKE ALL ON ops_mw_events FROM authenticated;
GRANT SELECT ON ops_mw_events TO authenticated;
GRANT INSERT ON ops_mw_events TO service_role;

-- ─────────────────────────────────────────────
-- 6. updated_at trigger for ops_incidents
-- ─────────────────────────────────────────────
-- Reuses ops_set_updated_at() from migration 056
CREATE TRIGGER trg_ops_incidents_updated
  BEFORE UPDATE ON ops_incidents
  FOR EACH ROW EXECUTE FUNCTION ops_set_updated_at();

-- ─────────────────────────────────────────────
-- 7. Cleanup function for ops_jobs and ops_mw_events
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.cleanup_observability_tables()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_jobs_deleted INT;
  v_mw_deleted   INT;
BEGIN
  DELETE FROM ops_jobs WHERE expires_at < now();
  GET DIAGNOSTICS v_jobs_deleted = ROW_COUNT;

  DELETE FROM ops_mw_events WHERE expires_at < now();
  GET DIAGNOSTICS v_mw_deleted = ROW_COUNT;

  RETURN jsonb_build_object(
    'jobs_deleted', v_jobs_deleted,
    'mw_events_deleted', v_mw_deleted,
    'ran_at', now()
  );
END;
$$;

COMMENT ON FUNCTION public.cleanup_observability_tables IS
  'Removes expired rows from ops_jobs (30d TTL) and ops_mw_events (7d TTL). Run daily via pg_cron.';

-- ─────────────────────────────────────────────
-- 8. Schedule cleanup cron jobs
-- ─────────────────────────────────────────────
-- cleanup_rate_limit_counters() — from migration 050, daily 03:00 UTC
SELECT cron.schedule(
  'cleanup-rate-limits-job',
  '0 3 * * *',
  $$
  SELECT public.cleanup_rate_limit_counters();
  $$
);

-- cleanup_expired_draft_jobs() — from migration 034, daily 03:30 UTC
SELECT cron.schedule(
  'cleanup-draft-jobs-job',
  '30 3 * * *',
  $$
  SELECT public.cleanup_expired_draft_jobs();
  $$
);

-- cleanup_observability_tables() — new, daily 04:00 UTC
SELECT cron.schedule(
  'cleanup-observability-job',
  '0 4 * * *',
  $$
  SELECT public.cleanup_observability_tables();
  $$
);
