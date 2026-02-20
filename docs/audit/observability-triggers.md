# T1-T4 Observability Trigger Definitions

> Date: 2026-02-20 | WI-OBS-1 | Migration: 073_observability_tables.sql

## Overview

Four trigger tiers define what "measurable" means before FastAPI migration.
All queries run against Supabase PostgreSQL via Dashboard > SQL Editor.
No Log Drain required (Team plan constraint).

**SoT(Single Source of Truth)**:
- `cron.job_run_details` — pg_cron execution history
- `net._http_response` — pg_net HTTP call results (6h TTL)
- `ops_incidents` — incident lifecycle (manual)
- `ops_jobs` — batch/cron job telemetry (30d TTL)
- `ops_mw_events` — middleware events (7d TTL)

---

## 0. Pre-check: Extension Availability

Run once to confirm observability data sources exist:

```sql
-- 0-1. pg_cron + pg_net extensions active
SELECT extname, extversion FROM pg_extension
WHERE extname IN ('pg_net', 'pg_cron');

-- 0-2. pg_net settings (hosted Supabase: read-only)
SELECT name, setting FROM pg_settings WHERE name LIKE 'pg_net%';

-- 0-3. cron schema exists
SELECT nspname FROM pg_namespace WHERE nspname = 'cron';

-- 0-4. Observability tables exist
SELECT tablename FROM pg_tables
WHERE tablename IN ('ops_incidents', 'ops_jobs', 'ops_mw_events');
```

---

## T1 — Error Rate / Batch Failure Rate

### Definition
Percentage of Edge Function invocations returning 5xx, plus pg_cron job failure rate.

### Data Sources
- `ops_mw_events` (`event_type = 'error_5xx'`) — Edge Function errors
- `cron.job_run_details` — pg_cron job results
- `net._http_response` — pg_net outbound call results (6h window)

### Queries

```sql
-- T1-A: cron job 24h failure/success
SELECT
  jobid,
  status,
  COUNT(*) AS runs,
  AVG(EXTRACT(EPOCH FROM (end_time - start_time))) AS avg_seconds
FROM cron.job_run_details
WHERE start_time >= now() - INTERVAL '24 hours'
GROUP BY jobid, status
ORDER BY jobid, status;

-- T1-B: cron recent failures (last 50)
SELECT
  jobid, status, return_message,
  start_time, end_time
FROM cron.job_run_details
WHERE start_time >= now() - INTERVAL '24 hours'
  AND status <> 'succeeded'
ORDER BY start_time DESC
LIMIT 50;

-- T1-C: pg_net 1h timeout/error/HTTP status distribution
SELECT
  date_trunc('minute', created) AS minute,
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE timed_out) AS timed_out,
  COUNT(*) FILTER (WHERE error_msg IS NOT NULL) AS error_rows,
  COUNT(*) FILTER (
    WHERE status_code BETWEEN 200 AND 299
      AND NOT timed_out
      AND error_msg IS NULL
  ) AS http_2xx
FROM net._http_response
WHERE created >= now() - INTERVAL '1 hour'
GROUP BY 1
ORDER BY 1;

-- T1-D: pg_net queue backlog
SELECT COUNT(*) AS pending_requests FROM net.http_request_queue;

-- T1-E: Edge Function 5xx rate (last 5 minutes)
SELECT
  fn_name,
  COUNT(*) FILTER (WHERE event_type = 'error_5xx') AS errors_5m,
  COUNT(*) AS total_events_5m,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE event_type = 'error_5xx')
    / NULLIF(COUNT(*), 0), 2
  ) AS error_rate_pct
FROM ops_mw_events
WHERE recorded_at > now() - INTERVAL '5 minutes'
GROUP BY fn_name
ORDER BY errors_5m DESC;
```

### Alarm Thresholds

| ID | Condition | Severity |
|----|-----------|----------|
| T1-AL1 | cron: 24h failure rate > 0.5% or > 10 failures/day | P2 (Warning) |
| T1-AL2 | cron: 3+ consecutive failures on same jobid | P0 (Blocker) |
| T1-AL3 | pg_net: 10+ timeouts in 1h or queue growing | P1 |
| T1-AL4 | Edge: error_rate_pct > 2% any 5-min window | P1 |
| T1-AL5 | payment-* function 5xx consecutive | P0 |

### Action
- T1-AL1/AL4: See `ops/runbooks/observability.md` Step 2
- T1-AL2/AL5: Declare incident per `ops/runbooks/incident.md`

---

## T2 — MTTR (Mean Time to Resolve)

### Definition
Average time from incident open to close, measured per severity level.

### Data Source
`ops_incidents` table (manual entry by ops staff).

### Queries

```sql
-- T2-A: Currently open incidents
SELECT
  id, title, severity, status, open_at,
  EXTRACT(EPOCH FROM (now() - open_at))::INT / 60 AS minutes_open,
  slack_thread, notion_wi
FROM ops_incidents
WHERE status <> 'closed'
ORDER BY severity ASC, open_at ASC;

-- T2-B: MTTR by severity (last 30 days)
SELECT
  severity,
  COUNT(*) AS incident_count,
  AVG(mttr_minutes) AS avg_mttr_min,
  PERCENTILE_CONT(0.95)
    WITHIN GROUP (ORDER BY mttr_minutes) AS p95_mttr_min,
  MAX(mttr_minutes) AS max_mttr_min
FROM ops_incidents
WHERE closed_at > now() - INTERVAL '30 days'
GROUP BY severity
ORDER BY severity;
```

### Alarm Thresholds

| ID | Condition | Severity |
|----|-----------|----------|
| T2-AL1 | P0 open > 90 minutes without mitigated_at | P0 Escalation |
| T2-AL2 | P0 avg MTTR > 120 min (30-day window) | P0 Process Review |
| T2-AL3 | P0 MTTR > 120 min occurring 2+ times/month | P0 Structural Fix |

### Action
- T2-AL1: Escalate in Slack #ops-incidents thread
- T2-AL2/AL3: Post-mortem + process improvement WI

---

## T3 — Long-Running Job Duration

### Definition
Scheduled or batch jobs exceeding expected duration, signaling capacity limits.

### Data Sources
- `ops_jobs` — general job telemetry
- `ai_draft_jobs` (migration 034) — AI-specific job latency
- `cron.job_run_details` — pg_cron built-in history

### Queries

```sql
-- T3-A: Currently running jobs (should be empty most of the time)
SELECT
  job_name, job_type, started_at,
  EXTRACT(EPOCH FROM (now() - started_at))::INT AS seconds_running,
  correlation_id
FROM ops_jobs
WHERE status = 'running'
ORDER BY started_at ASC;

-- T3-B: Job duration history (last 24h)
SELECT
  job_name,
  COUNT(*) AS runs,
  AVG(duration_ms) / 1000 AS avg_sec,
  MAX(duration_ms) / 1000 AS max_sec,
  COUNT(*) FILTER (WHERE status = 'failed') AS failures
FROM ops_jobs
WHERE started_at > now() - INTERVAL '24 hours'
GROUP BY job_name
ORDER BY avg_sec DESC;

-- T3-C: AI draft job latency (existing table)
SELECT
  status,
  COUNT(*) AS count,
  AVG(latency_ms) AS avg_ms,
  PERCENTILE_CONT(0.95)
    WITHIN GROUP (ORDER BY latency_ms) AS p95_ms
FROM ai_draft_jobs
WHERE created_at > now() - INTERVAL '24 hours'
GROUP BY status;

-- T3-D: pg_cron job history (built-in)
SELECT
  jobname, runid, status, return_message,
  start_time, end_time,
  EXTRACT(EPOCH FROM (end_time - start_time))::INT AS duration_sec
FROM cron.job_run_details
WHERE start_time > now() - INTERVAL '24 hours'
ORDER BY start_time DESC;

-- T3-E: Job type failure rate + P95 (last 7 days)
SELECT
  job_name,
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE status = 'failed') AS failed,
  PERCENTILE_CONT(0.95)
    WITHIN GROUP (ORDER BY duration_ms) AS p95_ms
FROM ops_jobs
WHERE started_at >= now() - INTERVAL '7 days'
  AND duration_ms IS NOT NULL
GROUP BY job_name
ORDER BY failed DESC, p95_ms DESC;
```

### Alarm Thresholds

| ID | Condition | Severity |
|----|-----------|----------|
| T3-AL1 | payment-reconcile running > 3 min (expected < 30s) | P1 |
| T3-AL2 | cleanup-* jobs running > 5 min | P2 |
| T3-AL3 | Any job_type p95 > 120,000ms (2 min) + failure rate increasing | P2 (Warning) |
| T3-AL4 | Job repeatedly hitting 150-400s Edge Background Tasks limit | FastAPI review |

### Action
- T3-AL1: Check payment-reconcile function logs in Dashboard
- T3-AL4: Open WI for FastAPI minimum boundary introduction

---

## T4 — Middleware Event Rate

### Definition
Abnormal rate of middleware events per function, indicating capacity/security issues.

### Data Source
`ops_mw_events` table (written by `_shared/mw_metrics.ts`).

### Queries

```sql
-- T4-A: Event summary per function per hour (last 6 hours)
SELECT
  fn_name, event_type,
  date_trunc('hour', recorded_at) AS hour_bucket,
  COUNT(*) AS event_count
FROM ops_mw_events
WHERE recorded_at > now() - INTERVAL '6 hours'
GROUP BY fn_name, event_type, hour_bucket
ORDER BY hour_bucket DESC, event_count DESC;

-- T4-B: Alarm query (last 1 hour, exceeding thresholds)
SELECT fn_name, event_type, COUNT(*) AS cnt
FROM ops_mw_events
WHERE recorded_at > now() - INTERVAL '1 hour'
GROUP BY fn_name, event_type
HAVING
  (event_type = 'rate_limited'    AND COUNT(*) > 100)
  OR (event_type = 'schema_invalid' AND COUNT(*) > 50)
  OR (event_type = 'circuit_open'   AND COUNT(*) > 0)
  OR (event_type = 'abuse_suspected' AND COUNT(*) > 10)
  OR (event_type = 'slow_request'   AND COUNT(*) > 20)
ORDER BY cnt DESC;

-- T4-C: Daily trend (last 7 days)
SELECT
  event_type,
  date_trunc('day', recorded_at) AS day,
  COUNT(*) AS cnt
FROM ops_mw_events
WHERE recorded_at > now() - INTERVAL '7 days'
GROUP BY event_type, day
ORDER BY day DESC, cnt DESC;
```

### Alarm Thresholds

| ID | Condition | Severity |
|----|-----------|----------|
| T4-AL1 | rate_limited > 100/hour for any function | P2 (Capacity) |
| T4-AL2 | schema_invalid > 50/hour | P2 (Client mismatch) |
| T4-AL3 | circuit_open > 0 in any window | P1 (External API down) |
| T4-AL4 | abuse_suspected > 10/hour | P1 (Active abuse) |
| T4-AL5 | slow_request > 20/hour for payment-* functions | P2 |
| T4-AL6 | Repeated rule gaps causing incidents | FastAPI review |

### Action
- T4-AL1: Investigate traffic source (bot/abuse)
- T4-AL3: Check external API status, consider circuit breaker
- T4-AL6: Open WI for common middleware layer (FastAPI minimum boundary)

---

## Baseline Period

Run T1-E, T3-B, T3-D, and T4-A queries daily for 2 weeks before adjusting thresholds.
Record results in Notion WI (WI-OBS-1) to establish baseline.
Thresholds above are starting estimates; adjust after baseline.

---

## Instrumented Edge Functions (Phase 1)

| Function | Events Emitted |
|----------|---------------|
| `ai-reply-suggest` | `rate_limited`, `slow_request` |
| `payment-checkout` | `rate_limited` |
| `ops-manage` | `schema_invalid` |

Additional functions can be instrumented incrementally by importing `emitMwEvent` from `_shared/mw_metrics.ts`.

---

## Related Documents

- `ops/runbooks/observability.md` — Daily ops routine (Korean)
- `ops/runbooks/incident.md` — Incident lifecycle
- `ops/runbooks/payments.md` — Payment-specific monitoring
- `supabase/migrations/073_observability_tables.sql` — Schema
- `supabase/functions/_shared/mw_metrics.ts` — Event emitter module
