-- ============================================
-- Migration: 041_partial_refund.sql
-- Purpose: 부분 환불 처리 시스템
-- Description: DT 구매 건에 대한 부분 환불 지원
--              (기존 process_refund_atomic은 전액 환불만 지원)
-- ============================================

-- ============================================
-- 1. dt_purchases에 부분 환불 추적 컬럼 추가
-- ============================================
ALTER TABLE dt_purchases ADD COLUMN IF NOT EXISTS refunded_dt INT DEFAULT 0;

-- refund_amount_krw, refund_reason 컬럼은 006_wallet_ledger.sql에서 이미 존재

-- ============================================
-- 2. 부분 환불 atomic 프로시저
-- ============================================
CREATE OR REPLACE FUNCTION public.process_partial_refund_atomic(
  p_order_id UUID,
  p_refund_dt INT,
  p_refund_reason TEXT DEFAULT 'Partial refund'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_purchase RECORD;
  v_wallet_id UUID;
  v_new_balance INT;
  v_available_dt INT;
  v_idempotency_key TEXT;
  v_refund_krw INT;
  v_new_status TEXT;
BEGIN
  -- 구매 건 잠금
  SELECT * INTO v_purchase
  FROM dt_purchases
  WHERE id = p_order_id
  FOR UPDATE;

  IF v_purchase IS NULL THEN
    RAISE EXCEPTION 'purchase_not_found: %', p_order_id;
  END IF;

  -- 상태 확인 (paid 또는 이미 부분 환불된 건만)
  IF v_purchase.status NOT IN ('paid', 'partial_refund') THEN
    RAISE EXCEPTION 'invalid_status: current=%, expected paid or partial_refund', v_purchase.status;
  END IF;

  -- 환불 가능한 DT 계산
  -- 총 DT - 사용된 DT - 이미 환불된 DT
  v_available_dt := (v_purchase.dt_amount + COALESCE(v_purchase.bonus_dt, 0))
                    - COALESCE(v_purchase.dt_used, 0)
                    - COALESCE(v_purchase.refunded_dt, 0);

  IF p_refund_dt <= 0 THEN
    RAISE EXCEPTION 'invalid_refund_amount: must be positive';
  END IF;

  IF p_refund_dt > v_available_dt THEN
    RAISE EXCEPTION 'refund_exceeds_available: requested=%, available=%', p_refund_dt, v_available_dt;
  END IF;

  -- 환불 기한 확인 (설정된 경우에만)
  IF v_purchase.refund_eligible_until IS NOT NULL
     AND v_purchase.refund_eligible_until < now() THEN
    RAISE EXCEPTION 'refund_period_expired: eligible_until=%',
      v_purchase.refund_eligible_until;
  END IF;

  -- 사용자 지갑 조회
  SELECT id INTO v_wallet_id
  FROM wallets
  WHERE user_id = v_purchase.user_id;

  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'wallet_not_found: user=%', v_purchase.user_id;
  END IF;

  -- 멱등성 키 (부분 환불은 동일 주문에 여러 번 가능하므로 타임스탬프 포함)
  v_idempotency_key := 'partial_refund:' || p_order_id::TEXT || ':' || extract(epoch from now())::TEXT;

  -- KRW 환불액 계산
  -- 보너스 DT는 환불 대상이 아님 → 실제 구매 DT 기준 비율
  IF v_purchase.dt_amount > 0 THEN
    -- 이미 환불된 DT를 제외한 실제 구매 DT 잔여분 중 환불
    v_refund_krw := FLOOR(
      (LEAST(p_refund_dt,
             v_purchase.dt_amount - COALESCE(v_purchase.refunded_dt, 0))::NUMERIC
       / v_purchase.dt_amount::NUMERIC)
      * v_purchase.price_krw
    );
    -- 음수 방지
    IF v_refund_krw < 0 THEN
      v_refund_krw := 0;
    END IF;
  ELSE
    v_refund_krw := 0;
  END IF;

  -- 1. 환불 원장 기록
  INSERT INTO ledger_entries (
    idempotency_key,
    from_wallet_id,
    amount_dt,
    entry_type,
    reference_type,
    reference_id,
    description,
    metadata,
    status
  ) VALUES (
    v_idempotency_key,
    v_wallet_id,
    p_refund_dt,
    'refund',
    'purchase',
    p_order_id,
    format('부분 환불: %s DT (%s)', p_refund_dt, p_refund_reason),
    jsonb_build_object(
      'partial', true,
      'refund_krw', v_refund_krw,
      'refund_dt', p_refund_dt,
      'available_before', v_available_dt,
      'reason', p_refund_reason
    ),
    'completed'
  );

  -- 2. 지갑 잔액 차감 (환불이므로 DT 회수)
  UPDATE wallets SET
    balance_dt = balance_dt - p_refund_dt,
    lifetime_refunded_dt = lifetime_refunded_dt + p_refund_dt,
    updated_at = now()
  WHERE id = v_wallet_id
  RETURNING balance_dt INTO v_new_balance;

  -- 잔액 부족 검증
  IF v_new_balance < 0 THEN
    RAISE EXCEPTION 'insufficient_balance_for_refund: balance would be %', v_new_balance;
  END IF;

  -- 3. 새 상태 결정
  -- 잔여 환불 가능 DT가 0이 되면 전액 환불 완료
  IF (COALESCE(v_purchase.refunded_dt, 0) + p_refund_dt)
     >= (v_purchase.dt_amount + COALESCE(v_purchase.bonus_dt, 0) - COALESCE(v_purchase.dt_used, 0))
  THEN
    v_new_status := 'refunded';
  ELSE
    v_new_status := 'partial_refund';
  END IF;

  -- 4. 구매 건 업데이트
  UPDATE dt_purchases SET
    status = v_new_status,
    refunded_dt = COALESCE(refunded_dt, 0) + p_refund_dt,
    refund_amount_krw = COALESCE(refund_amount_krw, 0) + v_refund_krw,
    refund_reason = CASE
      WHEN refund_reason IS NOT NULL AND refund_reason != ''
      THEN refund_reason || '; ' || p_refund_reason
      ELSE p_refund_reason
    END,
    refunded_at = now(),
    updated_at = now()
  WHERE id = p_order_id;

  -- 결과 반환
  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'refunded_dt', p_refund_dt,
    'refund_krw', v_refund_krw,
    'new_balance', v_new_balance,
    'new_status', v_new_status,
    'remaining_refundable_dt', v_available_dt - p_refund_dt
  );
END;
$$;

GRANT EXECUTE ON FUNCTION process_partial_refund_atomic TO service_role;

COMMENT ON FUNCTION process_partial_refund_atomic IS
'DT 구매 건에 대한 부분 환불 처리.
Admin 전용 (service_role). 동일 주문에 여러 번 부분 환불 가능.
KRW 환불액은 구매 DT 기준 비율로 계산 (보너스 DT 제외).';

-- ============================================
-- 3. 환불 이력 조회 헬퍼 (Admin용)
-- ============================================
CREATE OR REPLACE FUNCTION public.get_purchase_refund_history(p_order_id UUID)
RETURNS TABLE (
  ledger_entry_id UUID,
  refund_dt INT,
  refund_krw INT,
  reason TEXT,
  is_partial BOOLEAN,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    le.id as ledger_entry_id,
    le.amount_dt as refund_dt,
    (le.metadata->>'refund_krw')::INT as refund_krw,
    le.description as reason,
    COALESCE((le.metadata->>'partial')::BOOLEAN, false) as is_partial,
    le.created_at
  FROM ledger_entries le
  WHERE le.reference_type = 'purchase'
    AND le.reference_id = p_order_id
    AND le.entry_type = 'refund'
  ORDER BY le.created_at ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_purchase_refund_history TO service_role;

COMMENT ON FUNCTION get_purchase_refund_history IS
'특정 구매 건의 전체 환불 이력 조회 (전액 + 부분 환불 포함). Admin 전용.';
