-- ============================================
-- Migration 084: Atomic Funding Payment Processing
-- ============================================
--
-- PURPOSE:
-- funding-payment-webhook 의 비원자 순차 쓰기(funding_payments → funding_pledges)를
-- 단일 트랜잭션 RPC로 대체.
-- 크래시 시 pledge=pending + payment=paid 불일치 방지.
--
-- SECURITY: SECURITY DEFINER, auth.uid() 없음 (service_role 전용)
-- IDEMPOTENCY: FOR UPDATE 잠금 + status 체크로 중복 처리 방지
-- ============================================

CREATE OR REPLACE FUNCTION public.process_funding_payment_atomic(
  p_funding_payment_id UUID,
  p_pledge_id UUID,
  p_pg_transaction_id TEXT DEFAULT NULL,
  p_pg_payment_id TEXT DEFAULT NULL,
  p_pg_response JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_payment_status TEXT;
BEGIN
  -- 1) 행 잠금 (concurrent 요청 직렬화)
  SELECT status INTO v_payment_status
  FROM funding_payments
  WHERE id = p_funding_payment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'funding_payment_not_found'
      USING ERRCODE = 'P0002',
            DETAIL = p_funding_payment_id::TEXT;
  END IF;

  -- 2) 멱등성: 이미 처리됨
  IF v_payment_status = 'paid' THEN
    RETURN jsonb_build_object('already_processed', true);
  END IF;

  -- 3) 상태 가드: pending 이외 상태는 처리 거부
  IF v_payment_status != 'pending' THEN
    RAISE EXCEPTION 'funding_payment_not_pending'
      USING ERRCODE = '23514',
            DETAIL = format('current status: %s', v_payment_status);
  END IF;

  -- 4) 원자적 업데이트: funding_payments
  UPDATE funding_payments
  SET
    status = 'paid',
    paid_at = NOW(),
    pg_transaction_id = p_pg_transaction_id,
    pg_payment_id = p_pg_payment_id,
    pg_response = COALESCE(p_pg_response, pg_response)
  WHERE id = p_funding_payment_id;

  -- 5) 원자적 업데이트: funding_pledges (같은 트랜잭션)
  UPDATE funding_pledges
  SET status = 'confirmed'
  WHERE id = p_pledge_id
    AND status = 'pending';

  RETURN jsonb_build_object('success', true);
END;
$$;

-- service_role 전용 (Edge Function 에서만 호출)
REVOKE ALL ON FUNCTION public.process_funding_payment_atomic FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_funding_payment_atomic TO service_role;

COMMENT ON FUNCTION public.process_funding_payment_atomic IS
  'Atomically marks funding_payment as paid and funding_pledge as confirmed in one transaction. Idempotent via FOR UPDATE + status check. Called by funding-payment-webhook Edge Function.';
