-- ============================================================
-- 076: Revoke Dangerous RPC Public Access
-- ============================================================
-- P0 Security Fix: PostgreSQL grants EXECUTE to PUBLIC by default.
-- Functions with GRANT TO service_role but no REVOKE FROM PUBLIC
-- are callable by any authenticated user via PostgREST/client SDK.
--
-- This migration locks down SECURITY DEFINER functions that must
-- only be invoked by Edge Functions (service_role), and enables
-- missing RLS on encryption_metadata.
-- ============================================================

BEGIN;

-- ============================================================
-- P0-1: Payment Atomic Functions (DT free-charge bypass)
-- Edge Functions only: payment-webhook, payment-confirm,
--   payment-reconcile, refund-process
-- Client calls: NONE
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.process_payment_atomic(
  UUID, TEXT, UUID, UUID, INTEGER, INTEGER, INTEGER, TEXT
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.process_payment_atomic(
  UUID, TEXT, UUID, UUID, INTEGER, INTEGER, INTEGER, TEXT
) TO service_role;

REVOKE EXECUTE ON FUNCTION public.process_refund_atomic(
  UUID, TEXT
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.process_refund_atomic(
  UUID, TEXT
) TO service_role;

-- ============================================================
-- P0-2: Funding Pledge KRW (forge paid pledge bypass)
-- Edge Function: funding-pledge (with PortOne payment verification)
-- Client calls: supabase_funding_repository.dart (WILL BREAK — client
--   must be updated to call Edge Function instead)
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.process_funding_pledge_krw(
  UUID, UUID, UUID, INT, INT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.process_funding_pledge_krw(
  UUID, UUID, UUID, INT, INT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT
) TO service_role;

-- Related funding admin functions (service_role / cron only)

REVOKE EXECUTE ON FUNCTION public.refund_failed_campaign_pledges(UUID)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.refund_failed_campaign_pledges(UUID)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.complete_expired_campaigns()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_expired_campaigns()
  TO service_role;

-- ============================================================
-- P0-2 supplement: Chargeback processing (webhook only)
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.process_chargeback(
  UUID, TEXT, TEXT, INT, TEXT
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.process_chargeback(
  UUID, TEXT, TEXT, INT, TEXT
) TO service_role;

-- ============================================================
-- P0-3: DT Expiration (global wallet mutation)
-- Edge Function / cron only
-- Client calls: NONE
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.process_dt_expiration()
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.process_dt_expiration()
  TO service_role;

-- ============================================================
-- P0-4: Rate Limiting (DoS via counter manipulation)
-- Edge Function _shared/rate_limit.ts only
-- Client calls: NONE
-- Note: These functions had NO GRANT at all (default PUBLIC)
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.check_and_increment_rate_limit(
  TEXT, INTEGER, INTEGER
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.check_and_increment_rate_limit(
  TEXT, INTEGER, INTEGER
) TO service_role;

REVOKE EXECUTE ON FUNCTION public.cleanup_rate_limit_counters()
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.cleanup_rate_limit_counters()
  TO service_role;

-- ============================================================
-- Bonus: encryption_metadata — missing RLS
-- Table created in 011_encrypt_sensitive_data.sql without RLS.
-- No client should access this table directly.
-- ============================================================

ALTER TABLE public.encryption_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "encryption_metadata_deny_all"
  ON public.encryption_metadata
  FOR ALL
  USING (false)
  WITH CHECK (false);

COMMIT;
