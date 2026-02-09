-- ============================================
-- Migration: 047_funding_refund_krw.sql
-- Purpose: KRW 펀딩 환불 추적 테이블 + 배치 환불 함수
-- Description: PG사 환불 처리 상태 추적 및 배치 환불 큐
-- ============================================

-- ============================================
-- 1. 펀딩 환불 요청 큐 테이블
-- Edge Function이 PG사 환불 API를 호출하고 결과를 기록
-- ============================================
CREATE TABLE IF NOT EXISTS public.funding_refund_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pledge_id UUID NOT NULL REFERENCES funding_pledges(id),
  payment_id UUID NOT NULL REFERENCES funding_payments(id),
  campaign_id UUID NOT NULL REFERENCES funding_campaigns(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  -- 환불 정보
  refund_amount_krw INT NOT NULL CHECK (refund_amount_krw > 0),
  refund_reason TEXT NOT NULL DEFAULT 'campaign_failed',

  -- 원본 결제 정보 (PG사 환불 API 호출용)
  original_payment_order_id TEXT NOT NULL,
  original_pg_transaction_id TEXT,
  payment_provider TEXT NOT NULL,

  -- 처리 상태
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',         -- 환불 대기
    'processing',      -- PG사 API 호출 중
    'completed',       -- 환불 완료
    'failed',          -- 환불 실패
    'manual_required'  -- 수동 처리 필요
  )),

  -- PG사 환불 응답
  pg_refund_id TEXT,              -- PG사 환불 거래 ID
  pg_refund_response JSONB,       -- PG 응답 원본

  -- 재시도 관리
  retry_count INT DEFAULT 0,
  max_retries INT DEFAULT 3,
  last_error TEXT,
  next_retry_at TIMESTAMPTZ,

  -- 처리 시간
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- 멱등성
  idempotency_key TEXT UNIQUE
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_funding_refund_queue_status
  ON funding_refund_queue(status, created_at);
CREATE INDEX IF NOT EXISTS idx_funding_refund_queue_pending
  ON funding_refund_queue(status, next_retry_at)
  WHERE status IN ('pending', 'failed');
CREATE INDEX IF NOT EXISTS idx_funding_refund_queue_campaign
  ON funding_refund_queue(campaign_id);
CREATE INDEX IF NOT EXISTS idx_funding_refund_queue_pledge
  ON funding_refund_queue(pledge_id);

-- RLS
ALTER TABLE funding_refund_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own refund status"
  ON funding_refund_queue FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all refund queue"
  ON funding_refund_queue FOR ALL
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- 2. 캠페인 환불 큐 생성 함수
-- refund_failed_campaign_pledges()가 호출한 후
-- 이 함수로 환불 큐에 항목 추가
-- ============================================
CREATE OR REPLACE FUNCTION public.queue_campaign_refunds(p_campaign_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_campaign funding_campaigns;
  v_record RECORD;
  v_queued INT := 0;
  v_skipped INT := 0;
  v_errors TEXT[] := '{}';
  v_idempotency TEXT;
BEGIN
  -- 캠페인 확인
  SELECT * INTO v_campaign
  FROM funding_campaigns
  WHERE id = p_campaign_id;

  IF v_campaign IS NULL THEN
    RAISE EXCEPTION 'campaign_not_found';
  END IF;

  -- refund_pending 상태의 pledge + 관련 payment 조회
  FOR v_record IN
    SELECT
      fp.id AS pledge_id,
      fp.user_id,
      fp.amount_krw + COALESCE(fp.extra_support_krw, 0) AS total_krw,
      fpy.id AS payment_id,
      fpy.payment_order_id,
      fpy.pg_transaction_id,
      fpy.payment_provider
    FROM funding_pledges fp
    JOIN funding_payments fpy ON fpy.pledge_id = fp.id AND fpy.status = 'paid'
    WHERE fp.campaign_id = p_campaign_id
      AND fp.status = 'refund_pending'
  LOOP
    BEGIN
      -- 멱등성 키
      v_idempotency := 'campaign_refund:' || v_record.pledge_id::TEXT;

      -- 이미 큐에 존재하면 스킵
      IF EXISTS (
        SELECT 1 FROM funding_refund_queue
        WHERE idempotency_key = v_idempotency
      ) THEN
        v_skipped := v_skipped + 1;
        CONTINUE;
      END IF;

      -- 환불 큐에 추가
      INSERT INTO funding_refund_queue (
        pledge_id,
        payment_id,
        campaign_id,
        user_id,
        refund_amount_krw,
        refund_reason,
        original_payment_order_id,
        original_pg_transaction_id,
        payment_provider,
        idempotency_key
      ) VALUES (
        v_record.pledge_id,
        v_record.payment_id,
        p_campaign_id,
        v_record.user_id,
        v_record.total_krw,
        CASE
          WHEN v_campaign.status = 'cancelled' THEN 'campaign_cancelled'
          ELSE 'goal_not_reached'
        END,
        v_record.payment_order_id,
        v_record.pg_transaction_id,
        v_record.payment_provider,
        v_idempotency
      );

      v_queued := v_queued + 1;

    EXCEPTION WHEN OTHERS THEN
      v_errors := array_append(v_errors, v_record.pledge_id::TEXT || ':' || SQLERRM);
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'campaign_id', p_campaign_id,
    'queued', v_queued,
    'skipped', v_skipped,
    'errors', to_jsonb(v_errors),
    'executed_at', now()
  );
END;
$$;

GRANT EXECUTE ON FUNCTION queue_campaign_refunds TO service_role;

COMMENT ON FUNCTION queue_campaign_refunds IS
'캠페인 실패/취소 후 refund_pending 상태의 pledge들을 환불 큐에 추가.
Edge Function이 큐를 폴링하여 PG사 환불 API 호출.';

-- ============================================
-- 3. 환불 완료 처리 함수
-- Edge Function이 PG사 환불 성공 후 호출
-- ============================================
CREATE OR REPLACE FUNCTION public.complete_funding_refund(
  p_queue_id UUID,
  p_pg_refund_id TEXT DEFAULT NULL,
  p_pg_response JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_queue funding_refund_queue;
  v_result JSONB;
BEGIN
  -- 큐 항목 잠금
  SELECT * INTO v_queue FROM funding_refund_queue
  WHERE id = p_queue_id FOR UPDATE;

  IF v_queue IS NULL THEN
    RAISE EXCEPTION 'refund_queue_item_not_found';
  END IF;

  IF v_queue.status NOT IN ('pending', 'processing', 'failed') THEN
    RAISE EXCEPTION 'refund_already_processed: status=%', v_queue.status;
  END IF;

  -- 큐 상태 업데이트
  UPDATE funding_refund_queue SET
    status = 'completed',
    pg_refund_id = p_pg_refund_id,
    pg_refund_response = p_pg_response,
    processed_at = now()
  WHERE id = p_queue_id;

  -- funding_payment 환불 처리
  SELECT mark_funding_payment_refunded(
    v_queue.payment_id,
    v_queue.refund_amount_krw,
    v_queue.refund_reason,
    p_pg_refund_id
  ) INTO v_result;

  RETURN jsonb_build_object(
    'queue_id', p_queue_id,
    'pledge_id', v_queue.pledge_id,
    'refund_amount_krw', v_queue.refund_amount_krw,
    'payment_result', v_result,
    'completed_at', now()
  );
END;
$$;

GRANT EXECUTE ON FUNCTION complete_funding_refund TO service_role;

-- ============================================
-- 4. 환불 실패 기록 함수
-- ============================================
CREATE OR REPLACE FUNCTION public.fail_funding_refund(
  p_queue_id UUID,
  p_error TEXT,
  p_pg_response JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_queue funding_refund_queue;
  v_new_status TEXT;
BEGIN
  SELECT * INTO v_queue FROM funding_refund_queue
  WHERE id = p_queue_id FOR UPDATE;

  IF v_queue IS NULL THEN
    RAISE EXCEPTION 'refund_queue_item_not_found';
  END IF;

  -- 재시도 횟수 초과 시 manual_required
  IF v_queue.retry_count + 1 >= v_queue.max_retries THEN
    v_new_status := 'manual_required';
  ELSE
    v_new_status := 'failed';
  END IF;

  UPDATE funding_refund_queue SET
    status = v_new_status,
    retry_count = retry_count + 1,
    last_error = p_error,
    pg_refund_response = COALESCE(p_pg_response, pg_refund_response),
    next_retry_at = CASE
      WHEN v_new_status = 'failed' THEN
        now() + (INTERVAL '1 minute' * POWER(2, retry_count + 1))  -- 지수 백오프
      ELSE NULL
    END
  WHERE id = p_queue_id;

  RETURN jsonb_build_object(
    'queue_id', p_queue_id,
    'new_status', v_new_status,
    'retry_count', v_queue.retry_count + 1,
    'max_retries', v_queue.max_retries,
    'error', p_error
  );
END;
$$;

GRANT EXECUTE ON FUNCTION fail_funding_refund TO service_role;

-- ============================================
-- 5. 권한 부여
-- ============================================
GRANT ALL ON funding_refund_queue TO authenticated;
