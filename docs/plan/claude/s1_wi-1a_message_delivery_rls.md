# S1 WI-1A — message_delivery RLS (FULL DROP + recreate + assert)

Goal
- Close permissive INSERT hole on message_delivery.
- Preserve upsert correctness (INSERT ... ON CONFLICT may require SELECT policy checks).
- Prevent future bypass by asserting no unexpected policies remain.

Context (must keep in mind)
- Permissive policies are OR-combined when multiple policies apply to the same command.
- INSERT policies use WITH CHECK only (no USING).
- Upsert paths can involve additional checks; keep SELECT/INSERT/UPDATE aligned.

Changes
1) NEW migration: `supabase/migrations/068_fix_message_delivery_rls.sql`
2) In that migration:
   - DROP 3 existing policies by name:
     - "Users can view own delivery status"
     - "Users can update own read status"
     - "System can create delivery"
   - CREATE 3 safe policies:
     - delivery_select_own (SELECT, USING user_id = auth.uid())
     - delivery_insert_own (INSERT, WITH CHECK user_id = auth.uid())
     - delivery_update_own (UPDATE, USING + WITH CHECK user_id = auth.uid())
   - Add DO $$ assert:
     - If any other policy exists on message_delivery besides the 3 above -> RAISE EXCEPTION

Verification
- `supabase db reset` must succeed.
- Manual RLS tests:
  - user A inserts/updates row with user_id = user B -> rejected
  - user A inserts/updates own row -> allowed
- Upsert tests:
  - markAsRead / markChannelAsRead must work in authenticated user context.

Gates
- mcp__supabase_guard__prepush_report (migration lint + RLS audit) if available
- mcp__repo_doctor__run_all if available

Commit
- `S1 WI-1A: harden message_delivery RLS (own-row + assert)`
