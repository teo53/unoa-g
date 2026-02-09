-- ============================================
-- Migration: 042_chargeback_handling.sql
-- Purpose: 차지백(카드사 이의제기) 처리 시스템
-- Description: 차지백 접수 → DT 동결 → 분쟁 해결(승소/패소)
-- ============================================

-- ============================================
-- 1. ledger_entries.entry_type에 'chargeback' 추가
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
  'expiration',      -- DT expired (5-year limit)
  'chargeback'       -- Chargeback dispute
));

-- ============================================
-- 2. 차지백 분쟁 테이블
-- ============================================
CREATE TABLE IF NOT EXISTS public.chargeback_disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 관련 구매 건
  purchase_id UUID NOT NULL REFERENCES dt_purchases(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  -- 차지백 정보
  provider_dispute_id TEXT,                -- 결제사 분쟁 ID
  payment_provider TEXT NOT NULL,          -- 'portone', 'tosspayments'
  dispute_amount_krw INT NOT NULL,         -- 분쟁 금액 (원)
  dispute_reason TEXT,                     -- 카드사 사유 코드/설명

  -- 상태 워크플로우: opened → evidence_submitted → won/lost
  status TEXT NOT NULL DEFAULT 'opened' CHECK (status IN (
    'opened',              -- 차지백 접수, DT 동결
    'evidence_submitted',  -- 가맹점 증빙 자료 제출
    'won',                 -- 가맹점 승소 (차지백 취소, DT 복원)
    'lost'                 -- 가맹점 패소 (환불 확정, DT 차감)
  )),

  -- DT 영향
  dt_frozen INT DEFAULT 0,                -- 분쟁 중 동결된 DT
  dt_deducted INT DEFAULT 0,              -- 최종 차감된 DT (패소 시)

  -- 원장 참조
  freeze_ledger_entry_id UUID REFERENCES ledger_entries(id),
  deduct_ledger_entry_id UUID REFERENCES ledger_entries(id),

  -- 증빙 자료
  evidence_notes TEXT,                    -- 관리자 메모

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT now(),
  evidence_submitted_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_chargeback_disputes_purchase
  ON chargeback_disputes(purchase_id);
CREATE INDEX IF NOT EXISTS idx_chargeback_disputes_user
  ON chargeback_disputes(user_id);
CREATE INDEX IF NOT EXISTS idx_chargeback_disputes_status
  ON chargeback_disputes(status)
  WHERE status IN ('opened', 'evidence_submitted');
CREATE INDEX IF NOT EXISTS idx_chargeback_disputes_provider
  ON chargeback_disputes(payment_provider, provider_dispute_id);
CREATE INDEX IF NOT EXISTS idx_chargeback_disputes_created
  ON chargeback_disputes(created_at DESC);

-- RLS (admin/service_role만 접근)
ALTER TABLE chargeback_disputes ENABLE ROW LEVEL SECURITY;

-- Admin만 조회 가능
CREATE POLICY "Admins can view all chargebacks"
  ON chargeback_disputes FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Admins can manage all chargebacks"
  ON chargeback_disputes FOR ALL
  TO authenticated
  USING (public.is_admin());

-- updated_at 자동 갱신 트리거
CREATE TRIGGER trigger_chargeback_disputes_updated_at
  BEFORE UPDATE ON chargeback_disputes
  FOR EACH ROW EXECUTE FUNCTION update_funding_updated_at();

-- ============================================
-- 3. 차지백 접수 프로시저 (DT 동결)
-- ============================================
CREATE OR REPLACE FUNCTION public.process_chargeback(
  p_purchase_id UUID,
  p_provider_dispute_id TEXT,
  p_payment_provider TEXT,
  p_dispute_amount_krw INT,
  p_dispute_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_purchase RECORD;
  v_wallet wallets;
  v_dt_to_freeze INT;
  v_dispute chargeback_disputes;
  v_ledger_entry ledger_entries;
  v_idempotency_key TEXT;
BEGIN
  -- 멱등성 확인: 동일 purchase + dispute ID 조합
  SELECT * INTO v_dispute
  FROM chargeback_disputes
  WHERE purchase_id = p_purchase_id
    AND provider_dispute_id = p_provider_dispute_id;

  IF v_dispute.id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'already_processed', true,
      'dispute_id', v_dispute.id,
      'status', v_dispute.status
    );
  END IF;

  -- 구매 건 조회 및 잠금
  SELECT * INTO v_purchase
  FROM dt_purchases
  WHERE id = p_purchase_id
  FOR UPDATE;

  IF v_purchase IS NULL THEN
    RAISE EXCEPTION 'purchase_not_found: %', p_purchase_id;
  END IF;

  -- 동결할 DT 계산 (구매 총 DT - 이미 환불된 DT)
  v_dt_to_freeze := (v_purchase.dt_amount + COALESCE(v_purchase.bonus_dt, 0))
                     - COALESCE(v_purchase.refunded_dt, 0);
  IF v_dt_to_freeze < 0 THEN
    v_dt_to_freeze := 0;
  END IF;

  -- 사용자 지갑 조회 및 잠금
  SELECT * INTO v_wallet
  FROM wallets
  WHERE user_id = v_purchase.user_id
  FOR UPDATE;

  IF v_wallet.id IS NULL THEN
    -- 지갑이 없으면 동결 없이 분쟁만 기록
    v_dt_to_freeze := 0;
  ELSE
    -- 지갑 잔액이 동결량보다 적으면 가용 잔액만 동결
    IF v_wallet.balance_dt < v_dt_to_freeze THEN
      v_dt_to_freeze := v_wallet.balance_dt;
    END IF;
  END IF;

  -- 원장에 동결 기록
  v_idempotency_key := 'chargeback_freeze:' || p_purchase_id::TEXT || ':' || p_provider_dispute_id;

  IF v_dt_to_freeze > 0 AND v_wallet.id IS NOT NULL THEN
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
      v_wallet.id,
      v_dt_to_freeze,
      'chargeback',
      'purchase',
      p_purchase_id,
      format('차지백 분쟁 DT 동결: %s DT', v_dt_to_freeze),
      jsonb_build_object(
        'action', 'freeze',
        'dispute_amount_krw', p_dispute_amount_krw,
        'provider_dispute_id', p_provider_dispute_id,
        'reason', p_dispute_reason
      ),
      'pending'  -- pending = 분쟁 진행 중
    ) RETURNING * INTO v_ledger_entry;

    -- 지갑 잔액 차감 (동결)
    UPDATE wallets SET
      balance_dt = balance_dt - v_dt_to_freeze,
      updated_at = now()
    WHERE id = v_wallet.id;
  END IF;

  -- 분쟁 기록 생성
  INSERT INTO chargeback_disputes (
    purchase_id,
    user_id,
    provider_dispute_id,
    payment_provider,
    dispute_amount_krw,
    dispute_reason,
    status,
    dt_frozen,
    freeze_ledger_entry_id
  ) VALUES (
    p_purchase_id,
    v_purchase.user_id,
    p_provider_dispute_id,
    p_payment_provider,
    p_dispute_amount_krw,
    p_dispute_reason,
    'opened',
    v_dt_to_freeze,
    v_ledger_entry.id
  ) RETURNING * INTO v_dispute;

  RETURN jsonb_build_object(
    'dispute_id', v_dispute.id,
    'purchase_id', p_purchase_id,
    'user_id', v_purchase.user_id,
    'dt_frozen', v_dt_to_freeze,
    'dispute_amount_krw', p_dispute_amount_krw,
    'status', 'opened'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION process_chargeback TO service_role;

COMMENT ON FUNCTION process_chargeback IS
'차지백 접수 시 호출. 관련 DT를 동결(지갑에서 차감)하고 분쟁 기록 생성.
멱등성: purchase_id + provider_dispute_id 조합으로 중복 방지.';

-- ============================================
-- 4. 차지백 분쟁 해결 프로시저 (승소/패소)
-- ============================================
CREATE OR REPLACE FUNCTION public.resolve_chargeback(
  p_dispute_id UUID,
  p_resolution TEXT,  -- 'won' or 'lost'
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_dispute chargeback_disputes;
  v_wallet_id UUID;
  v_idempotency_key TEXT;
BEGIN
  -- 분쟁 기록 조회 및 잠금
  SELECT * INTO v_dispute
  FROM chargeback_disputes
  WHERE id = p_dispute_id
  FOR UPDATE;

  IF v_dispute IS NULL THEN
    RAISE EXCEPTION 'dispute_not_found: %', p_dispute_id;
  END IF;

  -- 이미 해결된 분쟁 확인
  IF v_dispute.status NOT IN ('opened', 'evidence_submitted') THEN
    RAISE EXCEPTION 'dispute_already_resolved: current_status=%', v_dispute.status;
  END IF;

  -- 사용자 지갑 조회
  SELECT id INTO v_wallet_id
  FROM wallets
  WHERE user_id = v_dispute.user_id;

  IF p_resolution = 'won' THEN
    -- ========================================
    -- 가맹점 승소: 동결 해제, DT 복원
    -- ========================================
    IF v_dispute.dt_frozen > 0 AND v_wallet_id IS NOT NULL THEN
      v_idempotency_key := 'chargeback_unfreeze:' || v_dispute.id::TEXT;

      -- 이미 처리되었는지 확인
      IF NOT EXISTS (SELECT 1 FROM ledger_entries WHERE idempotency_key = v_idempotency_key) THEN
        INSERT INTO ledger_entries (
          idempotency_key,
          to_wallet_id,
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
          v_dispute.dt_frozen,
          'adjustment',
          'chargeback',
          v_dispute.id,
          format('차지백 승소 DT 복원: %s DT', v_dispute.dt_frozen),
          jsonb_build_object(
            'action', 'unfreeze',
            'resolution', 'won',
            'notes', p_notes
          ),
          'completed'
        );

        -- 지갑 잔액 복원
        UPDATE wallets SET
          balance_dt = balance_dt + v_dispute.dt_frozen,
          updated_at = now()
        WHERE id = v_wallet_id;
      END IF;
    END IF;

    -- 동결 원장 상태를 reversed로 변경
    IF v_dispute.freeze_ledger_entry_id IS NOT NULL THEN
      UPDATE ledger_entries SET
        status = 'reversed',
        metadata = metadata || jsonb_build_object('resolved', 'won', 'resolved_at', now())
      WHERE id = v_dispute.freeze_ledger_entry_id;
    END IF;

  ELSIF p_resolution = 'lost' THEN
    -- ========================================
    -- 가맹점 패소: 동결 DT 확정 차감
    -- ========================================
    IF v_dispute.dt_frozen > 0 AND v_wallet_id IS NOT NULL THEN
      v_idempotency_key := 'chargeback_deduct:' || v_dispute.id::TEXT;

      IF NOT EXISTS (SELECT 1 FROM ledger_entries WHERE idempotency_key = v_idempotency_key) THEN
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
          v_dispute.dt_frozen,
          'chargeback',
          'chargeback',
          v_dispute.id,
          format('차지백 패소 DT 확정 차감: %s DT', v_dispute.dt_frozen),
          jsonb_build_object(
            'action', 'deduct',
            'resolution', 'lost',
            'notes', p_notes
          ),
          'completed'
        );
      END IF;
    END IF;

    -- 동결 원장 완료 처리
    IF v_dispute.freeze_ledger_entry_id IS NOT NULL THEN
      UPDATE ledger_entries SET
        status = 'completed',
        metadata = metadata || jsonb_build_object('resolved', 'lost', 'resolved_at', now())
      WHERE id = v_dispute.freeze_ledger_entry_id;
    END IF;

    -- 구매 건 상태 업데이트
    UPDATE dt_purchases SET
      status = 'refunded',
      refund_reason = COALESCE(refund_reason || '; ', '') || 'Chargeback lost',
      refunded_at = now(),
      updated_at = now()
    WHERE id = v_dispute.purchase_id;

  ELSE
    RAISE EXCEPTION 'invalid_resolution: must be "won" or "lost", got "%"', p_resolution;
  END IF;

  -- 분쟁 상태 업데이트
  UPDATE chargeback_disputes SET
    status = p_resolution,
    dt_deducted = CASE WHEN p_resolution = 'lost' THEN dt_frozen ELSE 0 END,
    evidence_notes = COALESCE(evidence_notes || E'\n', '') || COALESCE(p_notes, ''),
    resolved_at = now(),
    updated_at = now()
  WHERE id = p_dispute_id;

  RETURN jsonb_build_object(
    'dispute_id', p_dispute_id,
    'resolution', p_resolution,
    'dt_frozen', v_dispute.dt_frozen,
    'dt_restored', CASE WHEN p_resolution = 'won' THEN v_dispute.dt_frozen ELSE 0 END,
    'dt_deducted', CASE WHEN p_resolution = 'lost' THEN v_dispute.dt_frozen ELSE 0 END,
    'resolved_at', now()
  );
END;
$$;

GRANT EXECUTE ON FUNCTION resolve_chargeback TO service_role;

COMMENT ON FUNCTION resolve_chargeback IS
'차지백 분쟁 해결.
won: 가맹점 승소, 동결 DT 복원.
lost: 가맹점 패소, DT 확정 차감, 구매 건 refunded 처리.';

-- ============================================
-- 5. 차지백 통계 뷰 (Admin Dashboard용)
-- ============================================
CREATE OR REPLACE VIEW public.v_chargeback_summary AS
SELECT
  DATE_TRUNC('month', cd.created_at) as month,
  cd.payment_provider,
  cd.status,
  COUNT(*) as count,
  SUM(cd.dispute_amount_krw) as total_dispute_krw,
  SUM(cd.dt_frozen) as total_dt_frozen,
  SUM(cd.dt_deducted) as total_dt_deducted
FROM chargeback_disputes cd
GROUP BY DATE_TRUNC('month', cd.created_at), cd.payment_provider, cd.status
ORDER BY month DESC, cd.payment_provider;

COMMENT ON VIEW v_chargeback_summary IS '월별 차지백 통계 요약 (Admin Dashboard용)';

-- ============================================
-- 6. 활성 분쟁 조회 헬퍼 (Admin용)
-- ============================================
CREATE OR REPLACE FUNCTION public.get_active_chargebacks()
RETURNS TABLE (
  dispute_id UUID,
  purchase_id UUID,
  user_id UUID,
  provider_dispute_id TEXT,
  payment_provider TEXT,
  dispute_amount_krw INT,
  dispute_reason TEXT,
  status TEXT,
  dt_frozen INT,
  created_at TIMESTAMPTZ,
  days_open INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cd.id as dispute_id,
    cd.purchase_id,
    cd.user_id,
    cd.provider_dispute_id,
    cd.payment_provider,
    cd.dispute_amount_krw,
    cd.dispute_reason,
    cd.status,
    cd.dt_frozen,
    cd.created_at,
    EXTRACT(DAY FROM now() - cd.created_at)::INT as days_open
  FROM chargeback_disputes cd
  WHERE cd.status IN ('opened', 'evidence_submitted')
  ORDER BY cd.created_at ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_active_chargebacks TO service_role;

COMMENT ON FUNCTION get_active_chargebacks IS
'활성 차지백 분쟁 조회 (opened, evidence_submitted 상태). Admin 전용.';
