-- =====================================================
-- Migration 049: 보안 검수 수정
-- MCP security_guard + supabase_guard 결과 반영
-- =====================================================

-- =====================================================
-- 1. campaign_review_criteria RLS 누락 수정
-- 043_review_improvements.sql에서 테이블 생성 시 RLS 미설정
-- =====================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'campaign_review_criteria') THEN
    RAISE NOTICE 'campaign_review_criteria table does not exist, skipping RLS setup';
    RETURN;
  END IF;

  ALTER TABLE public.campaign_review_criteria ENABLE ROW LEVEL SECURITY;

  -- 읽기: 인증된 사용자 모두 (심사 기준은 공개 참조 데이터)
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'campaign_review_criteria_select' AND tablename = 'campaign_review_criteria') THEN
    CREATE POLICY campaign_review_criteria_select
      ON public.campaign_review_criteria
      FOR SELECT
      USING (auth.uid() IS NOT NULL);
  END IF;

  -- 쓰기(INSERT/UPDATE/DELETE): 관리자만
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'campaign_review_criteria_admin_manage' AND tablename = 'campaign_review_criteria') THEN
    CREATE POLICY campaign_review_criteria_admin_manage
      ON public.campaign_review_criteria
      FOR ALL
      USING (
        EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
      );
  END IF;
END $$;

-- =====================================================
-- 2. payment_webhook_logs RLS 정책 추가
-- 017_payment_webhook_logs.sql에서 RLS 활성화만 하고 정책 미정의
-- =====================================================

-- 읽기: 관리자만 (웹훅 로그에는 결제 관련 민감 정보 포함)
CREATE POLICY payment_webhook_logs_admin_select
  ON public.payment_webhook_logs
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
  );

-- 쓰기: service_role만 (Edge Function에서 INSERT)
-- RLS는 service_role에 적용되지 않으므로 별도 정책 불필요
-- 일반 사용자의 INSERT/UPDATE/DELETE 차단
CREATE POLICY payment_webhook_logs_deny_user_write
  ON public.payment_webhook_logs
  FOR INSERT
  WITH CHECK (false);
