# Cron Jobs Runbook

## Overview

UNO A uses `pg_cron` + `pg_net` to invoke Supabase Edge Functions on a schedule.

| Job | Schedule | Edge Function | Purpose |
|-----|----------|---------------|---------|
| `invoke-scheduled-dispatcher` | Every minute | `scheduled-dispatcher` | Dispatch pending messages, celebrations |
| `invoke-refresh-fallback-quotas` | Daily 03:00 UTC | `refresh-fallback-quotas` | Reset daily reply quotas |

## Setup

### 1. Enable Extensions

In the Supabase Dashboard:
- **Database > Extensions** > Enable `pg_cron`
- **Database > Extensions** > Enable `pg_net`

### 2. Store Secrets in Vault

Run in the SQL Editor:

```sql
SELECT vault.create_secret(
  'https://<project-ref>.supabase.co/functions/v1',
  'project_url'
);

SELECT vault.create_secret(
  '<your-cron-secret>',
  'cron_secret'
);
```

Make sure the same `CRON_SECRET` value is set as an Edge Function secret:
```bash
supabase secrets set CRON_SECRET=<your-cron-secret>
```

### 3. Run the Setup SQL

Execute `ops/sql/cron_setup.sql` in the SQL Editor.

## Verification

### Check Registered Jobs

```sql
SELECT jobid, schedule, command, nodename FROM cron.job;
```

Expected: 2 rows (`invoke-scheduled-dispatcher`, `invoke-refresh-fallback-quotas`)

### Check Execution History

```sql
SELECT jobid, runid, status, return_message,
       start_time, end_time
FROM cron.job_run_details
ORDER BY end_time DESC
LIMIT 20;
```

- `status = 'succeeded'` → job ran and HTTP call was made
- Check Edge Function logs for actual processing status

### Check Edge Function Logs

```bash
supabase functions logs scheduled-dispatcher --limit 10
supabase functions logs refresh-fallback-quotas --limit 10
```

## Troubleshooting

### Job Not Running

1. Verify extensions are enabled: `SELECT * FROM pg_extension WHERE extname IN ('pg_cron', 'pg_net');`
2. Verify Vault secrets exist: `SELECT name FROM vault.decrypted_secrets WHERE name IN ('project_url', 'cron_secret');`
3. Check job status: `SELECT * FROM cron.job;`

### Edge Function Returns 401

- Verify `CRON_SECRET` env var matches the Vault secret
- Check Edge Function uses `requireCronAuth(req)` from `_shared/cron_auth.ts`

### Removing a Job

```sql
SELECT cron.unschedule('invoke-scheduled-dispatcher');
```
