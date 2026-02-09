-- ============================================
-- Migration: 045_funding_krw_payments.sql
-- Purpose: 펀딩 KRW 결제 전용 테이블
-- Description: PG사(PortOne/TossPayments)를 통한 KRW 결제 추적
--   DT 원장(ledger_entries)과 완전히 분리된 KRW 결제 기록
-- ============================================

-- ============================================
-- 1. FUNDING_PAYMENTS 테이블
-- ============================================
CREATE TABLE IF NOT EXISTS public.funding_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pledge_id UUID NOT NULL REFERENCES funding_pledges(id) ON DELETE RESTRICT,
  campaign_id UUID NOT NULL REFERENCES funding_campaigns(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  -- 결제 금액
  amount_krw INT NOT NULL CHECK (amount_krw > 0),

  -- 결제 수단
  payment_method TEXT NOT NULL CHECK (payment_method IN (
    'card',              -- 신용/체크카드
    'bank_transfer',     -- 계좌이체
    'virtual_account',   -- 가상계좌
    'phone',             -- 휴대폰 결제
    'easy_pay'           -- 간편결제 (카카오페이, 네이버페이 등)
  )),

  -- PG사 정보
  payment_provider TEXT NOT NULL DEFAULT 'portone' CHECK (payment_provider IN (
    'portone',
    'tosspayments'
  )),
  payment_order_id TEXT UNIQUE NOT NULL,  -- 가맹점 주문번호
  pg_transaction_id TEXT,                 -- PG사 거래 고유번호
  pg_payment_id TEXT,                     -- PG사 결제 ID (PortOne paymentId)
  pg_response JSONB,                      -- PG 응답 원본 (디버깅용)

  -- 결제 상태
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',           -- 결제 대기
    'paid',              -- 결제 완료
    'failed',            -- 결제 실패
    'cancelled',         -- 사용자 취소
    'refunded',          -- 전액 환불 완료
    'partial_refunded'   -- 부분 환불
  )),

  -- 환불 추적
  refunded_amount_krw INT NOT NULL DEFAULT 0 CHECK (refunded_amount_krw >= 0),
  refund_reason TEXT,
  refund_pg_transaction_id TEXT,  -- 환불 PG 거래번호
  refunded_at TIMESTAMPTZ,

  -- 카드 정보 (마스킹)
  card_company TEXT,              -- 카드사 (삼성, 현대 등)
  card_number_masked TEXT,        -- 마스킹된 카드번호 (1234-****-****-5678)
  card_type TEXT,                 -- 'credit' / 'debit'
  installment_months INT DEFAULT 0,  -- 할부 개월수 (0=일시불)

  -- 타임스탬프
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  paid_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,

  -- 멱등성
  idempotency_key TEXT UNIQUE,

  -- 제약조건: 환불액은 결제액 초과 불가
  CONSTRAINT refund_not_exceed_payment CHECK (
    refunded_amount_krw <= amount_krw
  )
);

-- ============================================
-- 2. 인덱스
-- ============================================
CREATE INDEX IF NOT EXISTS idx_funding_payments_pledge
  ON funding_payments(pledge_id);
CREATE INDEX IF NOT EXISTS idx_funding_payments_campaign
  ON funding_payments(campaign_id, status);
CREATE INDEX IF NOT EXISTS idx_funding_payments_user
  ON funding_payments(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_funding_payments_order_id
  ON funding_payments(payment_order_id);
CREATE INDEX IF NOT EXISTS idx_funding_payments_pg_tx
  ON funding_payments(pg_transaction_id) WHERE pg_transaction_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_funding_payments_status
  ON funding_payments(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_funding_payments_pending_refund
  ON funding_payments(status) WHERE status IN ('paid', 'partial_refunded');

-- ============================================
-- 3. RLS 정책
-- ============================================
ALTER TABLE funding_payments ENABLE ROW LEVEL SECURITY;

-- 사용자: 본인 결제 내역 조회
CREATE POLICY "Users can view own funding payments"
  ON funding_payments FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- 크리에이터: 자기 캠페인의 결제 내역 조회
CREATE POLICY "Creators can view own campaign payments"
  ON funding_payments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns fc
      WHERE fc.id = funding_payments.campaign_id
      AND fc.creator_id = auth.uid()
    )
  );

-- 관리자: 전체 접근
CREATE POLICY "Admins can manage all funding payments"
  ON funding_payments FOR ALL
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- 4. 트리거: updated_at (status 변경 시 로깅 용)
-- ============================================
-- funding_payments에는 updated_at 없음 (이벤트 로그 성격)
-- 상태 변경은 새 레코드 or 컬럼 업데이트로 추적

-- ============================================
-- 5. 환불 처리 헬퍼 함수
-- (실제 PG사 환불 API 호출은 Edge Function에서 처리)
-- ============================================
CREATE OR REPLACE FUNCTION public.mark_funding_payment_refunded(
  p_payment_id UUID,
  p_refund_amount_krw INT,
  p_refund_reason TEXT DEFAULT 'campaign_failed',
  p_refund_pg_tx_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_payment funding_payments;
  v_new_status TEXT;
  v_total_refunded INT;
BEGIN
  -- 결제 건 잠금
  SELECT * INTO v_payment FROM funding_payments
  WHERE id = p_payment_id FOR UPDATE;

  IF v_payment IS NULL THEN
    RAISE EXCEPTION 'payment_not_found: %', p_payment_id;
  END IF;

  IF v_payment.status NOT IN ('paid', 'partial_refunded') THEN
    RAISE EXCEPTION 'invalid_payment_status: %, expected paid or partial_refunded', v_payment.status;
  END IF;

  -- 환불 가능 금액 확인
  v_total_refunded := v_payment.refunded_amount_krw + p_refund_amount_krw;
  IF v_total_refunded > v_payment.amount_krw THEN
    RAISE EXCEPTION 'refund_exceeds_payment: total_refund=%, payment_amount=%',
      v_total_refunded, v_payment.amount_krw;
  END IF;

  -- 상태 결정
  IF v_total_refunded >= v_payment.amount_krw THEN
    v_new_status := 'refunded';
  ELSE
    v_new_status := 'partial_refunded';
  END IF;

  -- 업데이트
  UPDATE funding_payments SET
    status = v_new_status,
    refunded_amount_krw = v_total_refunded,
    refund_reason = CASE
      WHEN refund_reason IS NOT NULL THEN refund_reason || '; ' || p_refund_reason
      ELSE p_refund_reason
    END,
    refund_pg_transaction_id = COALESCE(p_refund_pg_tx_id, refund_pg_transaction_id),
    refunded_at = now()
  WHERE id = p_payment_id;

  -- 관련 pledge 상태도 업데이트
  IF v_new_status = 'refunded' THEN
    UPDATE funding_pledges SET
      status = 'refunded',
      refunded_at = now()
    WHERE id = v_payment.pledge_id
      AND status IN ('paid', 'refund_pending');
  END IF;

  RETURN jsonb_build_object(
    'payment_id', p_payment_id,
    'pledge_id', v_payment.pledge_id,
    'refunded_amount_krw', p_refund_amount_krw,
    'total_refunded_krw', v_total_refunded,
    'new_status', v_new_status,
    'payment_amount_krw', v_payment.amount_krw
  );
END;
$$;

GRANT EXECUTE ON FUNCTION mark_funding_payment_refunded TO service_role;

COMMENT ON FUNCTION mark_funding_payment_refunded IS
'PG사 환불 완료 후 funding_payment 상태 업데이트.
실제 PG사 환불 API 호출은 Edge Function에서 수행.
이 함수는 DB 상태만 갱신 (payment + pledge).';

-- ============================================
-- 6. 캠페인별 KRW 결제 통계 뷰
-- ============================================
CREATE OR REPLACE VIEW funding_payment_stats AS
SELECT
  fp.campaign_id,
  fc.title AS campaign_title,
  fc.creator_id,
  COUNT(*) FILTER (WHERE fp.status = 'paid') AS paid_count,
  COUNT(*) FILTER (WHERE fp.status = 'refunded') AS refunded_count,
  COUNT(*) FILTER (WHERE fp.status = 'pending') AS pending_count,
  COALESCE(SUM(fp.amount_krw) FILTER (WHERE fp.status = 'paid'), 0) AS total_paid_krw,
  COALESCE(SUM(fp.refunded_amount_krw), 0) AS total_refunded_krw,
  COALESCE(SUM(fp.amount_krw) FILTER (WHERE fp.status = 'paid'), 0)
    - COALESCE(SUM(fp.refunded_amount_krw), 0) AS net_revenue_krw
FROM funding_payments fp
JOIN funding_campaigns fc ON fc.id = fp.campaign_id
GROUP BY fp.campaign_id, fc.title, fc.creator_id;

-- ============================================
-- 7. 권한 부여
-- ============================================
GRANT ALL ON funding_payments TO authenticated;
GRANT SELECT ON funding_payment_stats TO authenticated;
