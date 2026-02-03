-- ============================================
-- UNO A - Payment Webhook Logs Schema
-- Version: 1.0.0
--
-- PURPOSE:
-- - 결제 웹훅 이벤트 감사 로그
-- - 멱등성(idempotency) 보장을 위한 webhook_id 중복 체크
-- - 시그니처 검증 결과 기록
-- - 디버깅 및 분쟁 해결을 위한 원본 payload 저장
-- ============================================

-- ============================================
-- 1. PAYMENT_WEBHOOK_LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.payment_webhook_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 이벤트 정보
  event_type TEXT NOT NULL,                    -- 'Transaction.Paid', 'Transaction.Cancelled', etc.
  payment_provider TEXT NOT NULL,              -- 'portone', 'tosspayments'
  payment_order_id UUID,                       -- dt_purchases.id 참조 (nullable for failed lookups)

  -- 웹훅 식별자 (멱등성)
  webhook_id TEXT,                             -- Provider's event ID (unique per provider)
  webhook_timestamp TIMESTAMPTZ,               -- 웹훅 발생 시간 (provider 제공)

  -- 원본 데이터
  webhook_payload JSONB NOT NULL,              -- 원본 요청 body

  -- 시그니처 검증
  signature_valid BOOLEAN NOT NULL DEFAULT false,
  signature_error TEXT,                        -- 시그니처 검증 실패 시 에러 메시지

  -- 처리 상태
  processed_status TEXT DEFAULT 'pending' CHECK (
    processed_status IN ('pending', 'success', 'failed', 'duplicate', 'skipped')
  ),
  error_message TEXT,                          -- 처리 실패 시 에러 메시지
  retry_count INT DEFAULT 0,                   -- 재시도 횟수

  -- 교차 검증
  cross_verified BOOLEAN,                      -- Provider API로 결제 정보 교차 검증 완료 여부
  cross_verification_result JSONB,             -- 교차 검증 결과

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT now(),
  processed_at TIMESTAMPTZ                     -- 처리 완료 시점
);

-- 인덱스
-- webhook_id로 멱등성 체크 (provider별로 unique)
CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_webhook_logs_webhook_id
  ON payment_webhook_logs(webhook_id)
  WHERE webhook_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_payment_webhook_logs_provider ON payment_webhook_logs(payment_provider);
CREATE INDEX IF NOT EXISTS idx_payment_webhook_logs_status ON payment_webhook_logs(processed_status);
CREATE INDEX IF NOT EXISTS idx_payment_webhook_logs_order ON payment_webhook_logs(payment_order_id);
CREATE INDEX IF NOT EXISTS idx_payment_webhook_logs_event ON payment_webhook_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_payment_webhook_logs_created ON payment_webhook_logs(created_at);

-- 최근 실패한 웹훅 빠른 조회
CREATE INDEX IF NOT EXISTS idx_payment_webhook_logs_failed
  ON payment_webhook_logs(created_at)
  WHERE processed_status = 'failed';

-- ============================================
-- 2. RLS POLICIES
-- ============================================
ALTER TABLE payment_webhook_logs ENABLE ROW LEVEL SECURITY;

-- 웹훅 로그는 관리자만 조회 가능 (service_role)
-- 일반 사용자는 접근 불가
-- Admin 대시보드에서 service_role로 조회

-- ============================================
-- 3. HELPER FUNCTIONS
-- ============================================

-- 웹훅 중복 체크 (멱등성)
CREATE OR REPLACE FUNCTION public.is_webhook_processed(p_webhook_id TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM payment_webhook_logs
    WHERE webhook_id = p_webhook_id
      AND processed_status IN ('success', 'duplicate')
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- 최근 N일간 웹훅 통계 (Admin용)
CREATE OR REPLACE FUNCTION public.get_webhook_stats(p_days INT DEFAULT 7)
RETURNS TABLE (
  provider TEXT,
  total_count BIGINT,
  success_count BIGINT,
  failed_count BIGINT,
  duplicate_count BIGINT,
  invalid_signature_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pwl.payment_provider as provider,
    COUNT(*)::BIGINT as total_count,
    COUNT(*) FILTER (WHERE pwl.processed_status = 'success')::BIGINT as success_count,
    COUNT(*) FILTER (WHERE pwl.processed_status = 'failed')::BIGINT as failed_count,
    COUNT(*) FILTER (WHERE pwl.processed_status = 'duplicate')::BIGINT as duplicate_count,
    COUNT(*) FILTER (WHERE pwl.signature_valid = false)::BIGINT as invalid_signature_count
  FROM payment_webhook_logs pwl
  WHERE pwl.created_at >= now() - (p_days || ' days')::INTERVAL
  GROUP BY pwl.payment_provider;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 실패한 웹훅 재시도 대상 조회 (Admin용)
CREATE OR REPLACE FUNCTION public.get_failed_webhooks_for_retry(p_max_retries INT DEFAULT 3)
RETURNS SETOF payment_webhook_logs AS $$
  SELECT * FROM payment_webhook_logs
  WHERE processed_status = 'failed'
    AND retry_count < p_max_retries
    AND created_at >= now() - INTERVAL '24 hours'
  ORDER BY created_at ASC
  LIMIT 100;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 권한 부여 (service_role만 사용하므로 authenticated에는 부여 안함)
-- Admin 함수들은 service_role에서 직접 호출

-- ============================================
-- 4. CLEANUP POLICY (오래된 로그 정리)
-- ============================================
-- 90일 이상 된 성공 로그 정리 (실패 로그는 유지)
-- 이 함수는 스케줄러에서 주기적으로 호출

CREATE OR REPLACE FUNCTION public.cleanup_old_webhook_logs(p_days INT DEFAULT 90)
RETURNS INT AS $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM payment_webhook_logs
  WHERE created_at < now() - (p_days || ' days')::INTERVAL
    AND processed_status IN ('success', 'duplicate');

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 5. PAYMENT EVENTS SUMMARY VIEW (Admin Dashboard용)
-- ============================================
CREATE OR REPLACE VIEW public.v_payment_webhook_summary AS
SELECT
  DATE_TRUNC('day', created_at) as date,
  payment_provider,
  event_type,
  processed_status,
  COUNT(*) as count
FROM payment_webhook_logs
WHERE created_at >= now() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', created_at), payment_provider, event_type, processed_status
ORDER BY date DESC, payment_provider, event_type;

COMMENT ON TABLE payment_webhook_logs IS '결제 웹훅 이벤트 감사 로그 - 멱등성 및 디버깅 목적';
COMMENT ON VIEW v_payment_webhook_summary IS '결제 웹훅 일별 요약 통계 (Admin용)';
