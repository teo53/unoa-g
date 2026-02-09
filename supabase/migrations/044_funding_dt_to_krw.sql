-- ============================================
-- Migration: 044_funding_dt_to_krw.sql
-- Purpose: 펀딩 시스템 DT→KRW 완전 전환
-- Description: 펀딩은 KRW(원화) 전용. DT와 완전히 분리.
--   - DT = 메시징/팁/프라이빗카드 (폐쇄형 크레딧)
--   - KRW = 펀딩 결제/환불 (실제 원화, PG사 통과)
-- ============================================

-- ============================================
-- 1. funding_campaigns: _dt → _krw 컬럼 리네임
-- ============================================
ALTER TABLE funding_campaigns RENAME COLUMN goal_amount_dt TO goal_amount_krw;
ALTER TABLE funding_campaigns RENAME COLUMN current_amount_dt TO current_amount_krw;

-- CHECK 제약조건 재생성 (컬럼명 변경 반영)
ALTER TABLE funding_campaigns DROP CONSTRAINT IF EXISTS funding_campaigns_goal_amount_dt_check;
ALTER TABLE funding_campaigns DROP CONSTRAINT IF EXISTS funding_campaigns_current_amount_dt_check;
ALTER TABLE funding_campaigns ADD CONSTRAINT funding_campaigns_goal_amount_krw_check
  CHECK (goal_amount_krw >= 0);
ALTER TABLE funding_campaigns ADD CONSTRAINT funding_campaigns_current_amount_krw_check
  CHECK (current_amount_krw >= 0);

-- ============================================
-- 2. funding_reward_tiers: price_dt → price_krw
-- ============================================
ALTER TABLE funding_reward_tiers RENAME COLUMN price_dt TO price_krw;

ALTER TABLE funding_reward_tiers DROP CONSTRAINT IF EXISTS funding_reward_tiers_price_dt_check;
ALTER TABLE funding_reward_tiers ADD CONSTRAINT funding_reward_tiers_price_krw_check
  CHECK (price_krw > 0);

-- ============================================
-- 3. funding_pledges: _dt → _krw + PG 결제 컬럼 추가
-- ============================================

-- 3a. generated column 먼저 삭제 (의존성)
ALTER TABLE funding_pledges DROP COLUMN IF EXISTS total_amount_dt;

-- 3b. 컬럼 리네임
ALTER TABLE funding_pledges RENAME COLUMN amount_dt TO amount_krw;
ALTER TABLE funding_pledges RENAME COLUMN extra_support_dt TO extra_support_krw;

-- 3c. CHECK 제약조건 재생성
ALTER TABLE funding_pledges DROP CONSTRAINT IF EXISTS funding_pledges_amount_dt_check;
ALTER TABLE funding_pledges DROP CONSTRAINT IF EXISTS funding_pledges_extra_support_dt_check;
ALTER TABLE funding_pledges ADD CONSTRAINT funding_pledges_amount_krw_check
  CHECK (amount_krw > 0);
ALTER TABLE funding_pledges ADD CONSTRAINT funding_pledges_extra_support_krw_check
  CHECK (extra_support_krw >= 0);

-- 3d. generated column 재생성 (KRW 버전)
ALTER TABLE funding_pledges ADD COLUMN total_amount_krw INT
  GENERATED ALWAYS AS (amount_krw + extra_support_krw) STORED;

-- 3e. PG사 결제 연동 컬럼 추가
ALTER TABLE funding_pledges ADD COLUMN IF NOT EXISTS payment_order_id TEXT;
ALTER TABLE funding_pledges ADD COLUMN IF NOT EXISTS payment_method TEXT;
ALTER TABLE funding_pledges ADD COLUMN IF NOT EXISTS pg_transaction_id TEXT;

-- 3f. ledger_entry_id를 NULL 허용으로 변경 (KRW 펀딩은 DT 원장 미사용)
-- 기존에 NOT NULL 제약이 없으므로 이미 NULL 허용

-- 3g. PG 결제 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_funding_pledges_payment_order
  ON funding_pledges(payment_order_id) WHERE payment_order_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_funding_pledges_pg_transaction
  ON funding_pledges(pg_transaction_id) WHERE pg_transaction_id IS NOT NULL;

-- ============================================
-- 4. 기존 process_funding_pledge() 함수 DROP
-- (DT 지갑 차감 방식 → 더 이상 사용 안함)
-- ============================================
DROP FUNCTION IF EXISTS public.process_funding_pledge(
  UUID, UUID, UUID, UUID, INT, INT, TEXT, BOOLEAN, TEXT
);

-- ============================================
-- 5. 새 함수: process_funding_pledge_krw()
-- KRW PG 결제 확인 후 pledge 확정
-- (지갑 차감 없음, PG사가 이미 결제 처리)
-- ============================================
CREATE OR REPLACE FUNCTION public.process_funding_pledge_krw(
  p_campaign_id UUID,
  p_tier_id UUID,
  p_user_id UUID,
  p_amount_krw INT,
  p_extra_support_krw INT DEFAULT 0,
  p_payment_order_id TEXT DEFAULT NULL,
  p_payment_method TEXT DEFAULT NULL,
  p_pg_transaction_id TEXT DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL,
  p_is_anonymous BOOLEAN DEFAULT false,
  p_support_message TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_amount INT;
  v_campaign funding_campaigns;
  v_tier funding_reward_tiers;
  v_pledge funding_pledges;
BEGIN
  -- 총액 계산
  v_total_amount := p_amount_krw + COALESCE(p_extra_support_krw, 0);

  -- 멱등성 확인
  IF p_idempotency_key IS NOT NULL THEN
    SELECT * INTO v_pledge FROM funding_pledges WHERE idempotency_key = p_idempotency_key;
    IF v_pledge.id IS NOT NULL THEN
      RETURN jsonb_build_object(
        'pledge_id', v_pledge.id,
        'total_amount_krw', v_total_amount,
        'already_processed', true
      );
    END IF;
  END IF;

  -- 캠페인 잠금 및 유효성 검증
  SELECT * INTO v_campaign FROM funding_campaigns WHERE id = p_campaign_id FOR UPDATE;
  IF v_campaign.id IS NULL THEN
    RAISE EXCEPTION 'campaign_not_found';
  END IF;

  IF v_campaign.status != 'active' THEN
    RAISE EXCEPTION 'campaign_not_active';
  END IF;

  IF v_campaign.end_at IS NOT NULL AND v_campaign.end_at < now() THEN
    RAISE EXCEPTION 'campaign_ended';
  END IF;

  -- 리워드 티어 처리
  IF p_tier_id IS NOT NULL THEN
    SELECT * INTO v_tier FROM funding_reward_tiers
    WHERE id = p_tier_id AND campaign_id = p_campaign_id FOR UPDATE;

    IF v_tier.id IS NULL THEN
      RAISE EXCEPTION 'tier_not_found';
    END IF;

    IF NOT v_tier.is_active THEN
      RAISE EXCEPTION 'tier_not_active';
    END IF;

    IF v_tier.remaining_quantity IS NOT NULL AND v_tier.remaining_quantity <= 0 THEN
      RAISE EXCEPTION 'tier_sold_out';
    END IF;

    -- 티어 수량/통계 업데이트
    UPDATE funding_reward_tiers SET
      remaining_quantity = CASE
        WHEN remaining_quantity IS NOT NULL THEN remaining_quantity - 1
        ELSE NULL
      END,
      pledge_count = pledge_count + 1,
      updated_at = now()
    WHERE id = p_tier_id;
  END IF;

  -- pledge 레코드 생성 (DT 지갑 차감 없음 - KRW는 PG사가 처리)
  INSERT INTO funding_pledges (
    campaign_id,
    tier_id,
    user_id,
    amount_krw,
    extra_support_krw,
    status,
    payment_order_id,
    payment_method,
    pg_transaction_id,
    idempotency_key,
    is_anonymous,
    support_message,
    paid_at
  ) VALUES (
    p_campaign_id,
    p_tier_id,
    p_user_id,
    p_amount_krw,
    COALESCE(p_extra_support_krw, 0),
    'paid',
    p_payment_order_id,
    p_payment_method,
    p_pg_transaction_id,
    p_idempotency_key,
    p_is_anonymous,
    p_support_message,
    now()
  ) RETURNING * INTO v_pledge;

  -- 캠페인 통계 업데이트 (KRW)
  UPDATE funding_campaigns SET
    current_amount_krw = current_amount_krw + v_total_amount,
    backer_count = backer_count + 1,
    updated_at = now()
  WHERE id = p_campaign_id;

  RETURN jsonb_build_object(
    'pledge_id', v_pledge.id,
    'total_amount_krw', v_total_amount,
    'already_processed', false
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.process_funding_pledge_krw TO service_role;

COMMENT ON FUNCTION process_funding_pledge_krw IS
'KRW 펀딩 pledge 처리. DT 지갑 차감 없음.
PG사(PortOne/TossPayments)가 결제를 처리한 후 호출.
캠페인/티어 유효성 검증 + pledge 레코드 생성 + 캠페인 통계 업데이트.';

-- ============================================
-- 6. refund_failed_campaign_pledges() 업데이트
-- KRW 컬럼명 반영 (환불은 PG사 API로 별도 처리)
-- ============================================
CREATE OR REPLACE FUNCTION public.refund_failed_campaign_pledges(p_campaign_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_campaign funding_campaigns;
  v_pledge RECORD;
  v_total_krw INT;
  v_refund_count INT := 0;
  v_refund_total BIGINT := 0;
  v_skip_count INT := 0;
  v_errors TEXT[] := '{}';
BEGIN
  -- 캠페인 잠금 및 상태 확인
  SELECT * INTO v_campaign
  FROM funding_campaigns
  WHERE id = p_campaign_id
  FOR UPDATE;

  IF v_campaign IS NULL THEN
    RAISE EXCEPTION 'campaign_not_found';
  END IF;

  IF v_campaign.status NOT IN ('completed', 'cancelled') THEN
    RAISE EXCEPTION 'campaign_not_eligible: status=%, expected completed or cancelled', v_campaign.status;
  END IF;

  -- 목표 달성 캠페인은 환불 불가
  IF v_campaign.status = 'completed'
     AND v_campaign.goal_amount_krw > 0
     AND v_campaign.current_amount_krw >= v_campaign.goal_amount_krw THEN
    RAISE EXCEPTION 'campaign_succeeded: goal=%, current=%',
      v_campaign.goal_amount_krw, v_campaign.current_amount_krw;
  END IF;

  -- paid 상태 pledge 조회 및 refund_pending으로 변경
  FOR v_pledge IN
    SELECT
      fp.id,
      fp.user_id,
      fp.amount_krw,
      fp.extra_support_krw,
      fp.payment_order_id,
      fp.pg_transaction_id,
      (fp.amount_krw + COALESCE(fp.extra_support_krw, 0)) as total_krw
    FROM funding_pledges fp
    WHERE fp.campaign_id = p_campaign_id
      AND fp.status = 'paid'
    FOR UPDATE
  LOOP
    BEGIN
      v_total_krw := v_pledge.total_krw;

      -- pledge 상태 변경: paid → refund_pending
      -- 실제 PG사 환불은 Edge Function에서 처리
      UPDATE funding_pledges SET
        status = 'refund_pending',
        updated_at = now()
      WHERE id = v_pledge.id;

      v_refund_count := v_refund_count + 1;
      v_refund_total := v_refund_total + v_total_krw;

    EXCEPTION WHEN OTHERS THEN
      v_errors := array_append(v_errors, v_pledge.id::TEXT || ':' || SQLERRM);
      UPDATE funding_pledges SET status = 'paid'
      WHERE id = v_pledge.id AND status = 'refund_pending';
    END;
  END LOOP;

  -- 리워드 티어 수량 복원
  IF v_refund_count > 0 THEN
    UPDATE funding_reward_tiers SET
      remaining_quantity = CASE
        WHEN total_quantity IS NOT NULL THEN
          total_quantity - (
            SELECT COUNT(*)
            FROM funding_pledges
            WHERE campaign_id = p_campaign_id
              AND tier_id = funding_reward_tiers.id
              AND status = 'paid'
          )
        ELSE remaining_quantity
      END,
      pledge_count = (
        SELECT COUNT(*)
        FROM funding_pledges
        WHERE campaign_id = p_campaign_id
          AND tier_id = funding_reward_tiers.id
          AND status = 'paid'
      ),
      updated_at = now()
    WHERE campaign_id = p_campaign_id;
  END IF;

  RETURN jsonb_build_object(
    'campaign_id', p_campaign_id,
    'campaign_title', v_campaign.title,
    'campaign_status', v_campaign.status,
    'refund_pending_count', v_refund_count,
    'refund_pending_total_krw', v_refund_total,
    'skipped_count', v_skip_count,
    'errors', to_jsonb(v_errors),
    'note', 'PG refunds must be processed via Edge Function',
    'executed_at', now()
  );
END;
$$;

COMMENT ON FUNCTION refund_failed_campaign_pledges IS
'캠페인 실패/취소 시 모든 paid pledge를 refund_pending으로 변경.
KRW 환불이므로 DT 지갑 복원 없음. PG사 환불은 Edge Function에서 별도 처리.';

-- ============================================
-- 7. complete_expired_campaigns() 업데이트
-- KRW 컬럼명 반영
-- ============================================
CREATE OR REPLACE FUNCTION public.complete_expired_campaigns()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_campaign RECORD;
  v_completed INT := 0;
  v_refunded INT := 0;
  v_succeeded INT := 0;
  v_errors TEXT[] := '{}';
  v_refund_result JSONB;
BEGIN
  FOR v_campaign IN
    SELECT *
    FROM funding_campaigns
    WHERE status = 'active'
      AND end_at IS NOT NULL
      AND end_at < now()
    FOR UPDATE SKIP LOCKED
  LOOP
    BEGIN
      UPDATE funding_campaigns SET
        status = 'completed',
        completed_at = now(),
        updated_at = now()
      WHERE id = v_campaign.id;

      v_completed := v_completed + 1;

      -- 목표 미달 시 환불 처리 (KRW)
      IF v_campaign.goal_amount_krw > 0
         AND v_campaign.current_amount_krw < v_campaign.goal_amount_krw THEN
        v_refund_result := public.refund_failed_campaign_pledges(v_campaign.id);
        v_refunded := v_refunded + 1;
      ELSE
        v_succeeded := v_succeeded + 1;
      END IF;

    EXCEPTION WHEN OTHERS THEN
      v_errors := array_append(v_errors, v_campaign.id::TEXT || ':' || SQLERRM);
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'completed', v_completed,
    'succeeded', v_succeeded,
    'refund_pending', v_refunded,
    'errors', to_jsonb(v_errors),
    'executed_at', now()
  );
END;
$$;

COMMENT ON FUNCTION complete_expired_campaigns IS
'매일 실행: 종료일 경과한 active 캠페인을 completed로 변경.
목표 미달 캠페인은 refund_failed_campaign_pledges()로 환불 대기 처리.
KRW 환불이므로 PG사 환불은 Edge Function에서 별도 수행.';

-- ============================================
-- 8. ledger_entries에서 funding entry_type 유지
-- (기존 DT 기반 pledge 레코드의 하위 호환)
-- 새 KRW pledge는 ledger_entries를 사용하지 않음
-- ============================================
-- 'funding' entry_type은 기존 데이터 호환을 위해 유지
-- 새 KRW 결제는 funding_payments 테이블 사용 (045에서 생성)
