-- =====================================================
-- Migration: 075_payout_unique_period.sql
-- Purpose: Prevent duplicate payouts for the same creator+period
-- Risk: P0-05 — concurrent payout-calculate calls can create
--        duplicate payouts because no DB-level uniqueness exists
-- Fix: Partial unique index excluding cancelled/failed payouts
--       so re-calculation after cancellation is still possible.
-- Pre-deploy check:
--   SELECT creator_id, period_start, period_end, COUNT(*)
--   FROM payouts WHERE status NOT IN ('cancelled','failed')
--   GROUP BY creator_id, period_start, period_end HAVING COUNT(*) > 1;
-- =====================================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_payouts_unique_period
  ON public.payouts(creator_id, period_start, period_end)
  WHERE status NOT IN ('cancelled', 'failed');

COMMENT ON INDEX public.idx_payouts_unique_period IS
  'P0-05: Prevents duplicate payout creation for the same creator+period. Cancelled/failed excluded for re-runs.';
