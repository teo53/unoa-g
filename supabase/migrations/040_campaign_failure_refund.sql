-- ============================================
-- Migration: 040_campaign_failure_refund.sql
-- Purpose: 캠페인 실패/취소 시 펀딩 플레지 자동 환불
-- Description: 목표 미달 캠페인 종료 시 모든 후원자에게 DT 환불
-- ============================================

-- ============================================
-- 1. funding_pledges.status에 'refund_pending' 추가
-- ============================================
ALTER TABLE funding_pledges DROP CONSTRAINT IF EXISTS funding_pledges_status_check;
ALTER TABLE funding_pledges ADD CONSTRAINT funding_pledges_status_check CHECK (status IN (
  'pending',         -- Created but not yet processed
  'paid',            -- Payment confirmed, DT deducted
  'cancelled',       -- Cancelled by user before completion
  'refunded',        -- Refunded after campaign end
  'refund_pending'   -- Refund initiated, processing
));

-- ============================================
-- 2. 캠페인 실패 환불 처리 함수
-- ============================================
CREATE OR REPLACE FUNCTION public.refund_failed_campaign_pledges(p_campaign_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_campaign funding_campaigns;
  v_pledge RECORD;
  v_wallet_id UUID;
  v_total_dt INT;
  v_refund_count INT := 0;
  v_refund_total BIGINT := 0;
  v_skip_count INT := 0;
  v_errors TEXT[] := '{}';
  v_idempotency_key TEXT;
BEGIN
  -- 캠페인 잠금 및 상태 확인
  SELECT * INTO v_campaign
  FROM funding_campaigns
  WHERE id = p_campaign_id
  FOR UPDATE;

  IF v_campaign IS NULL THEN
    RAISE EXCEPTION 'campaign_not_found';
  END IF;

  -- 환불 가능한 상태 확인
  IF v_campaign.status NOT IN ('completed', 'cancelled') THEN
    RAISE EXCEPTION 'campaign_not_eligible: status=%, expected completed or cancelled', v_campaign.status;
  END IF;

  -- completed 상태인데 목표 달성한 경우 → 환불 불가
  IF v_campaign.status = 'completed'
     AND v_campaign.goal_amount_dt > 0
     AND v_campaign.current_amount_dt >= v_campaign.goal_amount_dt THEN
    RAISE EXCEPTION 'campaign_succeeded: goal=%, current=%',
      v_campaign.goal_amount_dt, v_campaign.current_amount_dt;
  END IF;

  -- 해당 캠페인의 모든 paid 플레지 조회 (잠금)
  FOR v_pledge IN
    SELECT
      fp.id,
      fp.user_id,
      fp.amount_dt,
      fp.extra_support_dt,
      fp.tier_id,
      (fp.amount_dt + COALESCE(fp.extra_support_dt, 0)) as total_dt
    FROM funding_pledges fp
    WHERE fp.campaign_id = p_campaign_id
      AND fp.status = 'paid'
    FOR UPDATE
  LOOP
    BEGIN
      v_total_dt := v_pledge.total_dt;

      -- 멱등성 확인
      v_idempotency_key := 'campaign_refund:' || v_pledge.id;
      IF EXISTS (SELECT 1 FROM ledger_entries WHERE idempotency_key = v_idempotency_key) THEN
        -- 이미 처리됨
        UPDATE funding_pledges SET status = 'refunded', refunded_at = now()
        WHERE id = v_pledge.id AND status = 'paid';
        v_skip_count := v_skip_count + 1;
        CONTINUE;
      END IF;

      -- 사용자 지갑 조회
      SELECT id INTO v_wallet_id
      FROM wallets
      WHERE user_id = v_pledge.user_id;

      IF v_wallet_id IS NULL THEN
        v_errors := array_append(v_errors, 'no_wallet:' || v_pledge.user_id::TEXT);
        CONTINUE;
      END IF;

      -- 플레지 상태를 refund_pending으로 변경
      UPDATE funding_pledges SET
        status = 'refund_pending',
        updated_at = now()
      WHERE id = v_pledge.id;

      -- 환불 원장 기록
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
        v_total_dt,
        'refund',
        'funding_pledge',
        v_pledge.id,
        format('펀딩 캠페인 %s 환불: %s DT',
          CASE WHEN v_campaign.status = 'cancelled' THEN '취소' ELSE '목표 미달' END,
          v_total_dt),
        jsonb_build_object(
          'campaign_id', p_campaign_id,
          'campaign_title', v_campaign.title,
          'campaign_status', v_campaign.status,
          'pledge_amount_dt', v_pledge.amount_dt,
          'extra_support_dt', COALESCE(v_pledge.extra_support_dt, 0),
          'refund_reason', CASE
            WHEN v_campaign.status = 'cancelled' THEN 'campaign_cancelled'
            ELSE 'goal_not_reached'
          END
        ),
        'completed'
      );

      -- 지갑 잔액 복원
      UPDATE wallets SET
        balance_dt = balance_dt + v_total_dt,
        lifetime_refunded_dt = lifetime_refunded_dt + v_total_dt,
        updated_at = now()
      WHERE id = v_wallet_id;

      -- 플레지 상태 완료
      UPDATE funding_pledges SET
        status = 'refunded',
        refunded_at = now()
      WHERE id = v_pledge.id;

      v_refund_count := v_refund_count + 1;
      v_refund_total := v_refund_total + v_total_dt;

    EXCEPTION WHEN OTHERS THEN
      -- 개별 플레지 실패 시 에러 기록하고 계속 진행
      v_errors := array_append(v_errors, v_pledge.id::TEXT || ':' || SQLERRM);
      -- 실패한 플레지는 paid 상태로 복원
      UPDATE funding_pledges SET status = 'paid'
      WHERE id = v_pledge.id AND status = 'refund_pending';
    END;
  END LOOP;

  -- 리워드 티어 수량 복원 (모든 환불 완료 후)
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
    'refunded_count', v_refund_count,
    'refunded_total_dt', v_refund_total,
    'skipped_count', v_skip_count,
    'errors', to_jsonb(v_errors),
    'executed_at', now()
  );
END;
$$;

GRANT EXECUTE ON FUNCTION refund_failed_campaign_pledges TO service_role;

COMMENT ON FUNCTION refund_failed_campaign_pledges IS
'캠페인 실패(목표 미달) 또는 취소 시 모든 paid 플레지를 환불.
각 플레지별 멱등성 보장. 개별 실패 시 나머지 계속 처리.';

-- ============================================
-- 3. 캠페인 자동 종료 확인 함수 (매일 실행)
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
  -- 종료일이 지난 active 캠페인 조회
  FOR v_campaign IN
    SELECT *
    FROM funding_campaigns
    WHERE status = 'active'
      AND end_at IS NOT NULL
      AND end_at < now()
    FOR UPDATE SKIP LOCKED
  LOOP
    BEGIN
      -- 캠페인 상태를 completed로 변경
      UPDATE funding_campaigns SET
        status = 'completed',
        completed_at = now(),
        updated_at = now()
      WHERE id = v_campaign.id;

      v_completed := v_completed + 1;

      -- 목표 미달 시 환불 처리
      IF v_campaign.goal_amount_dt > 0
         AND v_campaign.current_amount_dt < v_campaign.goal_amount_dt THEN
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
    'refunded', v_refunded,
    'errors', to_jsonb(v_errors),
    'executed_at', now()
  );
END;
$$;

GRANT EXECUTE ON FUNCTION complete_expired_campaigns TO service_role;

COMMENT ON FUNCTION complete_expired_campaigns IS
'매일 실행: 종료일 경과한 active 캠페인을 completed로 변경.
목표 미달 캠페인은 자동으로 refund_failed_campaign_pledges() 호출.';
