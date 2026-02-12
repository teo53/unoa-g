-- ============================================
-- Migration: 043_review_improvements.sql
-- Purpose: 리뷰에서 발견된 백엔드 개선사항 적용
-- Description:
--   1. 웹훅 로그 보존기간 90일→5년 연장 (세무 감사 대비)
--   2. 소득 유형별 원천징수율 분리 (3.3% vs 8.8%)
--   3. 정산 계좌 변경 이력 감사 테이블
--   4. 크리에이터 캠페인 승인 기준 참조 테이블
-- ============================================

-- ============================================
-- 1. 웹훅 로그 보존기간 연장 (90일 → 5년)
-- 세무 감사 대응을 위해 최소 5년 보존 필요
-- ============================================

-- 기존 cleanup 함수(INT 파라미터 버전)를 먼저 삭제
DROP FUNCTION IF EXISTS public.cleanup_old_webhook_logs(INT);

-- 새 함수 생성 (파라미터 없음, 5년 고정)
CREATE OR REPLACE FUNCTION public.cleanup_old_webhook_logs()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_deleted INT;
BEGIN
  -- 성공/중복 로그: 5년 후 삭제 (세무 감사 대응)
  -- 실패 로그: 영구 보존 (분쟁 대응)
  DELETE FROM payment_webhook_logs
  WHERE processed_status IN ('success', 'duplicate')
    AND created_at < now() - INTERVAL '5 years';

  GET DIAGNOSTICS v_deleted = ROW_COUNT;

  RETURN v_deleted;
END;
$$;

COMMENT ON FUNCTION cleanup_old_webhook_logs() IS
'웹훅 로그 정리: 성공/중복 로그는 5년 후 삭제 (세무 감사 대응).
실패 로그는 영구 보존. 기존 90일에서 5년으로 연장.';

-- ============================================
-- 2. 소득 유형별 원천징수율 테이블
-- 기타소득(팁/도네이션): 8.8%
-- 사업소득(구독/유료답장/프라이빗카드): 3.3%
-- ============================================

CREATE TABLE IF NOT EXISTS public.income_tax_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  income_type TEXT NOT NULL UNIQUE,     -- 'tip', 'paid_reply', 'private_card', 'subscription', 'funding'
  tax_category TEXT NOT NULL,           -- 'business_income' or 'other_income'
  withholding_rate NUMERIC(5,4) NOT NULL, -- 0.0330 = 3.3%, 0.0880 = 8.8%
  description TEXT,
  effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 소득 유형별 세율 초기 데이터
INSERT INTO income_tax_rates (income_type, tax_category, withholding_rate, description) VALUES
  ('tip', 'other_income', 0.0880, '후원/팁 - 기타소득세 8% + 지방소득세 0.8%'),
  ('paid_reply', 'business_income', 0.0330, '유료 답장 - 사업소득세 3% + 지방소득세 0.3%'),
  ('private_card', 'business_income', 0.0330, '프라이빗 카드 - 사업소득세 3% + 지방소득세 0.3%'),
  ('subscription', 'business_income', 0.0330, '구독 수익 - 사업소득세 3% + 지방소득세 0.3%'),
  ('funding', 'business_income', 0.0330, '펀딩 수익 - 사업소득세 3% + 지방소득세 0.3%')
ON CONFLICT (income_type) DO NOTHING;

COMMENT ON TABLE income_tax_rates IS
'소득 유형별 원천징수율 테이블.
기타소득(팁/도네이션): 8.8% (기타소득세 8% + 지방소득세 0.8%)
사업소득(구독/유료답장/프라이빗카드/펀딩): 3.3% (사업소득세 3% + 지방소득세 0.3%)
크리에이터가 사업자 등록한 경우 세율이 다를 수 있으며, payout_settings.tax_type으로 관리.';

-- 소득 유형별 세율 조회 헬퍼
CREATE OR REPLACE FUNCTION public.get_withholding_rate(p_income_type TEXT)
RETURNS NUMERIC
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  v_rate NUMERIC;
BEGIN
  SELECT withholding_rate INTO v_rate
  FROM income_tax_rates
  WHERE income_type = p_income_type
    AND effective_from <= CURRENT_DATE
  ORDER BY effective_from DESC
  LIMIT 1;

  -- 기본값: 3.3%
  RETURN COALESCE(v_rate, 0.0330);
END;
$$;

GRANT EXECUTE ON FUNCTION get_withholding_rate TO service_role;

-- ============================================
-- 3. 정산 계좌 변경 이력 감사 테이블
-- ============================================

CREATE TABLE IF NOT EXISTS public.payout_account_change_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id),
  account_id UUID, -- creator_payout_accounts.id (nullable if account was deleted)

  -- 변경 내용 (민감 정보는 마스킹)
  change_type TEXT NOT NULL CHECK (change_type IN (
    'created',           -- 새 계좌 등록
    'updated',           -- 계좌 정보 변경
    'verified',          -- 계좌 인증 완료
    'deactivated',       -- 계좌 비활성화
    'primary_changed'    -- 기본 계좌 변경
  )),

  -- 변경 전/후 (마스킹된 정보)
  previous_bank_code TEXT,
  previous_account_last4 TEXT,
  new_bank_code TEXT,
  new_account_last4 TEXT,

  -- 메타 정보
  changed_by UUID REFERENCES auth.users(id), -- 변경한 사용자 (admin 또는 본인)
  ip_address TEXT,
  user_agent TEXT,

  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_payout_account_change_log_creator
  ON payout_account_change_log(creator_id);
CREATE INDEX idx_payout_account_change_log_created
  ON payout_account_change_log(created_at);

ALTER TABLE payout_account_change_log ENABLE ROW LEVEL SECURITY;

-- 본인 + admin만 조회 가능
CREATE POLICY payout_account_change_log_select ON payout_account_change_log
  FOR SELECT USING (
    auth.uid() = creator_id OR
    EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
  );

COMMENT ON TABLE payout_account_change_log IS
'정산 계좌 변경 이력 감사 테이블.
계좌 등록, 변경, 인증, 비활성화 등 모든 변경사항을 기록.
민감 정보는 마스킹하여 저장 (은행코드 + 끝4자리만).';

-- ============================================
-- 4. 크리에이터 캠페인 승인 기준 참조 테이블
-- ============================================

CREATE TABLE IF NOT EXISTS public.campaign_review_criteria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,           -- 'content', 'legal', 'quality', 'financial'
  criterion TEXT NOT NULL,          -- 승인 기준 항목
  description TEXT,                 -- 세부 설명
  is_mandatory BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 기본 승인 기준 데이터
INSERT INTO campaign_review_criteria (category, criterion, description, is_mandatory, sort_order) VALUES
  ('content', '펀딩 제목 및 설명의 정확성', '허위/과장 표현 없이 프로젝트 내용이 명확하게 기술되어 있는가', true, 1),
  ('content', '리워드 실현 가능성', '약속한 리워드를 실제로 제공할 수 있는 합리적 근거가 있는가', true, 2),
  ('content', '이미지/미디어 적절성', '저작권 침해, 선정적/폭력적 콘텐츠가 없는가', true, 3),
  ('legal', '관련 법규 준수', '전자상거래법, 소비자보호법 등 관련 법규에 위배되지 않는가', true, 4),
  ('legal', '지식재산권 침해 여부', '제3자의 상표, 저작권, 특허 등을 침해하지 않는가', true, 5),
  ('quality', '목표금액 합리성', '프로젝트 규모 대비 목표금액이 합리적인가', false, 6),
  ('quality', '펀딩 기간 적정성', '목표 달성을 위한 충분한 기간이 설정되어 있는가', false, 7),
  ('financial', '크리에이터 본인인증 완료', '크리에이터가 본인인증(신원확인)을 완료했는가', true, 8),
  ('financial', '정산 계좌 등록 및 인증', '유효한 정산 계좌가 등록되고 인증되었는가', true, 9)
ON CONFLICT DO NOTHING;

COMMENT ON TABLE campaign_review_criteria IS
'크리에이터 펀딩 캠페인 승인 기준 참조 테이블.
관리자 심사 시 참고하는 체크리스트 항목.
API/앱을 통해 크리에이터에게 최소 가이드라인으로 노출.';

-- 승인 기준 조회 (공개용)
CREATE OR REPLACE FUNCTION public.get_campaign_review_criteria()
RETURNS TABLE (
  category TEXT,
  criterion TEXT,
  description TEXT,
  is_mandatory BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    crc.category,
    crc.criterion,
    crc.description,
    crc.is_mandatory
  FROM campaign_review_criteria crc
  ORDER BY crc.sort_order ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_campaign_review_criteria TO authenticated;
GRANT EXECUTE ON FUNCTION get_campaign_review_criteria TO service_role;

COMMENT ON FUNCTION get_campaign_review_criteria IS
'펀딩 캠페인 승인 기준 목록 조회. 인증된 사용자 모두 접근 가능.
크리에이터가 캠페인 생성 전 가이드라인을 확인할 수 있도록 공개.';
