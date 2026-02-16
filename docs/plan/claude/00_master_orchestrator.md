# Master Orchestrator (v2.2)

You are Claude Code. Apply `docs/plan/sprints_v2_2.md` exactly.

Non-negotiables
- Never commit secrets (keys, URLs with secrets, service_role, etc).
- 1 WI = 1 PR = 1 Notion Work Item.
- Demo mode behavior must remain unchanged.
- For any DB change: prove `supabase db reset` works on a clean local stack.

Start order
## Sprint 0 (Preflight) FIRST
1) Ensure `scripts/preflight_db_smoke.sql` exists exactly.
2) Run:
   - supabase start
   - supabase db reset
   - psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/preflight_db_smoke.sql
3) Decision:
   - If WARNING about remaining_replies/period_* appears -> run WI-1C first in Sprint 1.
   - If db reset fails -> fix migrations so db reset passes, then proceed.

Branch & PR discipline
- Branch naming: `s{N}/wi-{id}-{short-name}`
- Each WI:
  1) implement
  2) run all relevant gates
  3) commit with message `S{N} WI-{id}: <short summary>`
  4) open PR with:
     - Change summary (files, behavior)
     - Tests run (commands + outputs)
     - Risk + rollback plan

Gates (must paste results into PR)
- Flutter: flutter analyze, flutter test
- Web: cd apps/web && npm run build, npm run lint, npm run type-check
- Repo/Supabase/Security: mcp__repo_doctor__run_all, mcp__supabase_guard__prepush_report, mcp__security_guard__precommit_gate
