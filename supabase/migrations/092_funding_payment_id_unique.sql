-- =====================================================
-- Migration: 073_funding_payment_id_unique.sql
-- Purpose: Prevent paymentId replay attacks on funding pledges
-- Risk: P0-03 — same PG payment can be reused for multiple pledges
--        because pg_payment_id has no UNIQUE constraint
-- Fix: Partial unique index on (payment_provider, pg_payment_id)
--       so the same PG transaction cannot back multiple pledges.
-- Pre-deploy check:
--   SELECT pg_payment_id, payment_provider, COUNT(*)
--   FROM funding_payments WHERE pg_payment_id IS NOT NULL
--   GROUP BY pg_payment_id, payment_provider HAVING COUNT(*) > 1;
-- =====================================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_funding_payments_unique_pg_payment
  ON public.funding_payments(payment_provider, pg_payment_id)
  WHERE pg_payment_id IS NOT NULL;

COMMENT ON INDEX public.idx_funding_payments_unique_pg_payment IS
  'P0-03: Prevents payment ID replay — same PG payment cannot back multiple funding pledges.';
