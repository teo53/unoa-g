-- ============================================
-- Migration: 039_dt_expiration.sql
-- Purpose: DT 만료 처리 시스템
-- Description: 전자금융거래법 준수를 위한 DT 유효기간(5년) 및 만료 처리
-- ============================================

-- ============================================
-- 1. dt_purchases.status에 'expired' 추가
-- ============================================
ALTER TABLE dt_purchases DROP CONSTRAINT IF EXISTS dt_purchases_status_check;
ALTER TABLE dt_purchases ADD CONSTRAINT dt_purchases_status_check CHECK (status IN (
  'pending',        -- Created, awaiting payment
  'paid',           -- Payment confirmed, DT credited
  'cancelled',      -- Cancelled before payment
  'refunded',       -- Fully refunded
  'partial_refund', -- Partially refunded
  'failed',         -- Payment failed
  'expired'         -- DT expired (5-year limit)
));

-- ============================================
-- 2. dt_purchases에 만료일 컬럼 추가
-- ============================================
ALTER TABLE dt_purchases ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

-- 기존 paid 주문에 5년 만료 설정 (paid_at 기준)
UPDATE dt_purchases
SET expires_at = paid_at + INTERVAL '5 years'
WHERE status = 'paid'
  AND expires_at IS NULL
  AND paid_at IS NOT NULL;

-- 향후 결제 시 자동 설정을 위한 트리거
CREATE OR REPLACE FUNCTION public.set_dt_purchase_expiry()
RETURNS TRIGGER AS $$
BEGIN
  -- paid 상태로 변경될 때 만료일 설정
  IF NEW.status = 'paid' AND OLD.status != 'paid' AND NEW.expires_at IS NULL THEN
    NEW.expires_at := COALESCE(NEW.paid_at, now()) + INTERVAL '5 years';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_dt_purchase_expiry ON dt_purchases;
CREATE TRIGGER trigger_set_dt_purchase_expiry
  BEFORE UPDATE ON dt_purchases
  FOR EACH ROW EXECUTE FUNCTION set_dt_purchase_expiry();

-- 만료 대상 빠른 조회를 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_dt_purchases_expiry
  ON dt_purchases(expires_at)
  WHERE status = 'paid' AND expires_at IS NOT NULL;

-- ============================================
-- 3. ledger_entries.entry_type에 'expiration' 추가
-- ============================================
ALTER TABLE ledger_entries DROP CONSTRAINT IF EXISTS ledger_entries_entry_type_check;
ALTER TABLE ledger_entries ADD CONSTRAINT ledger_entries_entry_type_check CHECK (entry_type IN (
  'purchase',        -- User buys DT
  'tip',             -- Fan tips creator
  'paid_reply',      -- Fan pays for reply token
  'private_card',    -- Fan buys private card
  'refund',          -- Refund to user
  'payout',          -- Creator withdraws (DT -> KRW)
  'adjustment',      -- Admin adjustment
  'bonus',           -- Promotional bonus
  'subscription',    -- Subscription payment
  'funding',         -- Funding pledge
  'expiration'       -- DT expired (5-year limit)
));

-- ============================================
-- 4. DT 만료 처리 함수 (월 1회 실행)
-- ============================================
CREATE OR REPLACE FUNCTION public.process_dt_expiration()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_purchase RECORD;
  v_wallet_id UUID;
  v_remaining_dt INT;
  v_processed INT := 0;
  v_total_expired_dt BIGINT := 0;
  v_errors TEXT[] := '{}';
  v_idempotency_key TEXT;
BEGIN
  -- 만료된 미사용 DT가 있는 구매 건 조회
  FOR v_purchase IN
    SELECT *
    FROM dt_purchases
    WHERE status = 'paid'
      AND expires_at IS NOT NULL
      AND expires_at < now()
      AND (dt_amount + COALESCE(bonus_dt, 0) - COALESCE(dt_used, 0)) > 0
    ORDER BY expires_at ASC
    FOR UPDATE SKIP LOCKED  -- 동시 실행 방지
  LOOP
    BEGIN
      -- 잔여 DT 계산
      v_remaining_dt := v_purchase.dt_amount + COALESCE(v_purchase.bonus_dt, 0)
                        - COALESCE(v_purchase.dt_used, 0);

      IF v_remaining_dt <= 0 THEN
        CONTINUE;
      END IF;

      -- 멱등성 확인
      v_idempotency_key := 'expiration:' || v_purchase.id;
      IF EXISTS (SELECT 1 FROM ledger_entries WHERE idempotency_key = v_idempotency_key) THEN
        -- 이미 처리됨, 상태만 업데이트
        UPDATE dt_purchases SET status = 'expired', updated_at = now()
        WHERE id = v_purchase.id AND status = 'paid';
        CONTINUE;
      END IF;

      -- 사용자 지갑 조회
      SELECT id INTO v_wallet_id
      FROM wallets
      WHERE user_id = v_purchase.user_id
      FOR UPDATE;

      IF v_wallet_id IS NULL THEN
        v_errors := array_append(v_errors, 'no_wallet:' || v_purchase.user_id::TEXT);
        CONTINUE;
      END IF;

      -- 원장 기록 (만료)
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
        v_remaining_dt,
        'expiration',
        'purchase',
        v_purchase.id,
        format('DT 만료 (유효기간 5년 경과): %s DT', v_remaining_dt),
        jsonb_build_object(
          'purchase_id', v_purchase.id,
          'original_dt', v_purchase.dt_amount,
          'bonus_dt', COALESCE(v_purchase.bonus_dt, 0),
          'used_dt', COALESCE(v_purchase.dt_used, 0),
          'expired_dt', v_remaining_dt,
          'paid_at', v_purchase.paid_at,
          'expires_at', v_purchase.expires_at
        ),
        'completed'
      );

      -- 지갑 잔액 차감
      UPDATE wallets SET
        balance_dt = GREATEST(balance_dt - v_remaining_dt, 0),
        updated_at = now()
      WHERE id = v_wallet_id;

      -- 구매 건 상태 업데이트
      UPDATE dt_purchases SET
        status = 'expired',
        updated_at = now()
      WHERE id = v_purchase.id;

      v_processed := v_processed + 1;
      v_total_expired_dt := v_total_expired_dt + v_remaining_dt;

    EXCEPTION WHEN OTHERS THEN
      v_errors := array_append(v_errors, v_purchase.id::TEXT || ':' || SQLERRM);
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'processed', v_processed,
    'total_expired_dt', v_total_expired_dt,
    'errors', to_jsonb(v_errors),
    'executed_at', now()
  );
END;
$$;

GRANT EXECUTE ON FUNCTION process_dt_expiration TO service_role;

COMMENT ON FUNCTION process_dt_expiration IS
'월 1회 실행: 유효기간(5년) 경과한 DT 구매 건의 미사용 잔여 DT를 만료 처리.
전자금융거래법 준수. SKIP LOCKED으로 동시 실행 안전.';

-- ============================================
-- 5. 만료 예정 DT 조회 헬퍼 (사용자 알림용)
-- ============================================
CREATE OR REPLACE FUNCTION public.get_expiring_dt_summary(
  p_user_id UUID,
  p_within_days INT DEFAULT 90
)
RETURNS TABLE (
  purchase_id UUID,
  remaining_dt INT,
  expires_at TIMESTAMPTZ,
  days_until_expiry INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    dp.id as purchase_id,
    (dp.dt_amount + COALESCE(dp.bonus_dt, 0) - COALESCE(dp.dt_used, 0)) as remaining_dt,
    dp.expires_at,
    EXTRACT(DAY FROM dp.expires_at - now())::INT as days_until_expiry
  FROM dt_purchases dp
  WHERE dp.user_id = p_user_id
    AND dp.status = 'paid'
    AND dp.expires_at IS NOT NULL
    AND dp.expires_at <= now() + (p_within_days || ' days')::INTERVAL
    AND (dp.dt_amount + COALESCE(dp.bonus_dt, 0) - COALESCE(dp.dt_used, 0)) > 0
  ORDER BY dp.expires_at ASC;
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION get_expiring_dt_summary TO authenticated;

COMMENT ON FUNCTION get_expiring_dt_summary IS
'특정 사용자의 만료 예정 DT 요약 조회. 기본 90일 이내 만료 예정 건 반환.';
