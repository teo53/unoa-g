# Sprint 0 — Preflight: DB Reset + Runtime Smoke

Goal
- Ensure the repo can boot from clean DB state AND detect runtime-failure patterns early.
- Preflight is a hard gate before Sprint 1 starts.

Deliverables
1) Add `scripts/preflight_db_smoke.sql` exactly as specified in the plan.
2) Confirm local run:
   - supabase start
   - supabase db reset
   - psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/preflight_db_smoke.sql

Acceptance criteria
- No ERROR
- If WARNING about remaining_replies/period_* exists:
  - Document it in PR
  - Set Sprint 1 execution order: run WI-1C first

Commit
- `S0: add db reset + runtime smoke preflight`

PR notes
- Attach command outputs
- Confirm secrets not included
