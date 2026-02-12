-- ============================================
-- Migration: 046_settlement_tax.sql
-- Purpose: 소득유형별 세율 테이블 + 정산 명세서 + payout_settings 확장
-- Description:
--   사업소득 3.3% (소득세3% + 지방세0.3%)
--   기타소득 8.8% (소득세8% + 지방세0.8%)
--   세금계산서 0% (사업자가 직접 신고)
-- ============================================

-- ============================================
-- 1. 소득유형별 원천징수 세율 테이블
-- income_tax_rates 테이블이 이미 다른 스키마로 존재하므로
-- 필요한 컬럼만 추가 (ALTER TABLE)
-- ============================================

-- 기존 테이블이 없는 경우 생성 (초기 배포용)
CREATE TABLE IF NOT EXISTS public.income_tax_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  income_type TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 필요 컬럼 추가 (기존 테이블에 없는 경우만)
ALTER TABLE public.income_tax_rates ADD COLUMN IF NOT EXISTS label_ko TEXT;
ALTER TABLE public.income_tax_rates ADD COLUMN IF NOT EXISTS description_ko TEXT;
ALTER TABLE public.income_tax_rates ADD COLUMN IF NOT EXISTS tax_rate NUMERIC(5,2);
ALTER TABLE public.income_tax_rates ADD COLUMN IF NOT EXISTS income_tax_rate NUMERIC(5,2);
ALTER TABLE public.income_tax_rates ADD COLUMN IF NOT EXISTS local_tax_rate NUMERIC(5,2);
ALTER TABLE public.income_tax_rates ADD COLUMN IF NOT EXISTS requires_business_registration BOOLEAN DEFAULT false;
ALTER TABLE public.income_tax_rates ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.income_tax_rates ADD COLUMN IF NOT EXISTS display_order INT DEFAULT 0;

-- 기존 CHECK 제약조건 삭제 (있을 경우) — 새 income_type 값 허용
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'income_tax_rates_income_type_check'
    AND table_name = 'income_tax_rates'
    AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.income_tax_rates DROP CONSTRAINT income_tax_rates_income_type_check;
  END IF;
END $$;

-- 기존 NOT NULL 컬럼을 NULLABLE로 변경 (새 스키마와 공존)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'income_tax_rates' AND column_name = 'tax_category' AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE public.income_tax_rates ALTER COLUMN tax_category DROP NOT NULL;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'income_tax_rates' AND column_name = 'withholding_rate' AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE public.income_tax_rates ALTER COLUMN withholding_rate DROP NOT NULL;
  END IF;
END $$;

-- 기본 세율 삽입 (기존 데이터와 공존)
INSERT INTO income_tax_rates (income_type, label_ko, description_ko, tax_rate, income_tax_rate, local_tax_rate, requires_business_registration, display_order)
VALUES
  ('business_income', '사업소득 (3.3%)', '프리랜서/개인사업자 기본 원천징수. 소득세 3% + 지방소득세 0.3%', 3.30, 3.00, 0.30, false, 1),
  ('other_income', '기타소득 (8.8%)', '기타소득 원천징수. 소득세 8% + 지방소득세 0.8%. 필요경비 60% 적용 후 세율.', 8.80, 8.00, 0.80, false, 2),
  ('invoice', '세금계산서 (0%)', '사업자등록증 보유 사업자. 원천징수 없이 직접 부가세 신고.', 0.00, 0.00, 0.00, true, 3)
ON CONFLICT (income_type) DO UPDATE SET
  label_ko = EXCLUDED.label_ko,
  description_ko = EXCLUDED.description_ko,
  tax_rate = EXCLUDED.tax_rate,
  income_tax_rate = EXCLUDED.income_tax_rate,
  local_tax_rate = EXCLUDED.local_tax_rate,
  requires_business_registration = EXCLUDED.requires_business_registration,
  display_order = EXCLUDED.display_order;

-- RLS
ALTER TABLE income_tax_rates ENABLE ROW LEVEL SECURITY;

-- 정책 (존재할 수 있으므로 DROP IF EXISTS 먼저)
DROP POLICY IF EXISTS "Authenticated users can view tax rates" ON income_tax_rates;
CREATE POLICY "Authenticated users can view tax rates"
  ON income_tax_rates FOR SELECT
  TO authenticated
  USING (is_active = true);

DROP POLICY IF EXISTS "Admins can manage tax rates" ON income_tax_rates;
CREATE POLICY "Admins can manage tax rates"
  ON income_tax_rates FOR ALL
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- 2. payout_settings 확장 (소득유형 + 사업자등록)
-- ============================================
ALTER TABLE payout_settings ADD COLUMN IF NOT EXISTS income_type TEXT DEFAULT 'business_income';
ALTER TABLE payout_settings ADD COLUMN IF NOT EXISTS business_registration_number_encrypted TEXT;
ALTER TABLE payout_settings ADD COLUMN IF NOT EXISTS business_registration_verified BOOLEAN DEFAULT false;
ALTER TABLE payout_settings ADD COLUMN IF NOT EXISTS business_registration_verified_at TIMESTAMPTZ;

-- ============================================
-- 3. 정산 명세서 테이블 (월별 상세 내역)
-- ============================================
CREATE TABLE IF NOT EXISTS public.settlement_statements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_id UUID NOT NULL REFERENCES payouts(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES auth.users(id),

  -- 정산 기간
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,

  -- === DT 수익 (메시징 관련) ===
  dt_tips_count INT DEFAULT 0,
  dt_tips_gross INT DEFAULT 0,
  dt_cards_count INT DEFAULT 0,
  dt_cards_gross INT DEFAULT 0,
  dt_replies_count INT DEFAULT 0,
  dt_replies_gross INT DEFAULT 0,
  dt_total_gross INT DEFAULT 0,

  -- DT → KRW 변환
  dt_to_krw_rate NUMERIC(10,2) NOT NULL DEFAULT 1.0,
  dt_revenue_krw INT DEFAULT 0,

  -- === KRW 수익 (펀딩) ===
  funding_campaigns_count INT DEFAULT 0,
  funding_pledges_count INT DEFAULT 0,
  funding_revenue_krw INT DEFAULT 0,

  -- === 합산 ===
  total_revenue_krw INT NOT NULL DEFAULT 0,
  platform_fee_rate NUMERIC(5,2) NOT NULL DEFAULT 20.00,
  platform_fee_krw INT NOT NULL DEFAULT 0,
  subtotal_krw INT NOT NULL DEFAULT 0,

  -- === 세금 ===
  income_type TEXT NOT NULL DEFAULT 'business_income',
  tax_rate NUMERIC(5,2) NOT NULL DEFAULT 3.30,
  income_tax_krw INT NOT NULL DEFAULT 0,
  local_tax_krw INT NOT NULL DEFAULT 0,
  withholding_tax_krw INT NOT NULL DEFAULT 0,

  -- === 최종 지급액 ===
  net_payout_krw INT NOT NULL DEFAULT 0,

  -- PDF 명세서
  pdf_url TEXT,
  pdf_generated_at TIMESTAMPTZ,

  -- 타임스탬프
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- 유니크 제약: 동일 기간/크리에이터 중복 방지
  CONSTRAINT unique_settlement_period UNIQUE (creator_id, period_start, period_end)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_settlement_statements_creator
  ON settlement_statements(creator_id, period_start DESC);
CREATE INDEX IF NOT EXISTS idx_settlement_statements_payout
  ON settlement_statements(payout_id);
CREATE INDEX IF NOT EXISTS idx_settlement_statements_period
  ON settlement_statements(period_start, period_end);

-- RLS
ALTER TABLE settlement_statements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own settlement statements" ON settlement_statements;
CREATE POLICY "Creators can view own settlement statements"
  ON settlement_statements FOR SELECT
  TO authenticated
  USING (creator_id = auth.uid());

DROP POLICY IF EXISTS "Admins can manage all settlement statements" ON settlement_statements;
CREATE POLICY "Admins can manage all settlement statements"
  ON settlement_statements FOR ALL
  TO authenticated
  USING (public.is_admin());

-- 트리거: updated_at
DROP TRIGGER IF EXISTS update_settlement_statements_updated_at ON settlement_statements;
CREATE TRIGGER update_settlement_statements_updated_at
  BEFORE UPDATE ON settlement_statements
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- 4. 세율 조회 헬퍼 함수
-- ============================================
CREATE OR REPLACE FUNCTION public.get_withholding_rate(p_income_type TEXT)
RETURNS NUMERIC AS $$
DECLARE
  v_rate NUMERIC;
BEGIN
  SELECT tax_rate INTO v_rate
  FROM income_tax_rates
  WHERE income_type = p_income_type
    AND is_active = true;

  RETURN COALESCE(v_rate, 3.30);
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION get_withholding_rate TO authenticated;
GRANT EXECUTE ON FUNCTION get_withholding_rate TO service_role;

-- ============================================
-- 5. 크리에이터별 적용 세율 조회 함수
-- ============================================
CREATE OR REPLACE FUNCTION public.get_creator_tax_info(p_creator_id UUID)
RETURNS TABLE (
  income_type TEXT,
  tax_rate NUMERIC,
  income_tax_rate NUMERIC,
  local_tax_rate NUMERIC,
  label_ko TEXT,
  has_override BOOLEAN
) AS $$
DECLARE
  v_income_type TEXT;
  v_withholding_rate NUMERIC;
  v_tax_rate_record RECORD;
BEGIN
  -- 크리에이터 설정 조회
  SELECT ps.income_type, ps.withholding_tax_rate
  INTO v_income_type, v_withholding_rate
  FROM payout_settings ps WHERE ps.creator_id = p_creator_id;

  -- 소득유형 결정 (설정 > 기본값)
  income_type := COALESCE(v_income_type, 'business_income');

  -- 세율 조회
  SELECT itr.tax_rate, itr.income_tax_rate, itr.local_tax_rate, itr.label_ko
  INTO v_tax_rate_record
  FROM income_tax_rates itr
  WHERE itr.income_type = get_creator_tax_info.income_type
    AND itr.is_active = true;

  -- override 확인
  IF v_withholding_rate IS NOT NULL THEN
    tax_rate := v_withholding_rate * 100;
    has_override := true;
  ELSE
    tax_rate := COALESCE(v_tax_rate_record.tax_rate, 3.30);
    has_override := false;
  END IF;

  income_tax_rate := COALESCE(v_tax_rate_record.income_tax_rate, 3.00);
  local_tax_rate := COALESCE(v_tax_rate_record.local_tax_rate, 0.30);
  label_ko := COALESCE(v_tax_rate_record.label_ko, '사업소득 (3.3%)');

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION get_creator_tax_info TO authenticated;
GRANT EXECUTE ON FUNCTION get_creator_tax_info TO service_role;

-- ============================================
-- 6. calculate_creator_payout() 업데이트
-- ============================================
DROP FUNCTION IF EXISTS public.calculate_creator_payout(UUID, DATE, DATE, NUMERIC, NUMERIC);

CREATE OR REPLACE FUNCTION public.calculate_creator_payout(
  p_creator_id UUID,
  p_period_start DATE,
  p_period_end DATE,
  p_platform_fee_rate NUMERIC DEFAULT 0.20,
  p_withholding_tax_rate NUMERIC DEFAULT 0.033
)
RETURNS TABLE (
  gross_dt INT,
  gross_krw INT,
  platform_fee_krw INT,
  withholding_tax_krw INT,
  net_krw INT,
  tip_count INT,
  tip_total_dt INT,
  private_card_count INT,
  private_card_total_dt INT,
  funding_campaign_count INT,
  funding_pledge_count INT,
  funding_total_krw INT
) AS $$
DECLARE
  v_gross_dt INT := 0;
  v_tip_count INT := 0;
  v_tip_total_dt INT := 0;
  v_card_count INT := 0;
  v_card_total_dt INT := 0;
  v_funding_campaign_count INT := 0;
  v_funding_pledge_count INT := 0;
  v_funding_total_krw INT := 0;
  v_dt_revenue_krw INT := 0;
  v_total_revenue_krw INT := 0;
BEGIN
  -- 1. DT 수익: 팁/후원
  SELECT COUNT(*), COALESCE(SUM(creator_share_dt), 0)
  INTO v_tip_count, v_tip_total_dt
  FROM dt_donations
  WHERE to_creator_id = p_creator_id
    AND created_at >= p_period_start
    AND created_at < p_period_end + INTERVAL '1 day';

  -- 2. DT 수익: 프라이빗카드
  SELECT COUNT(*), COALESCE(SUM(pc.price_paid_dt), 0)::INT
  INTO v_card_count, v_card_total_dt
  FROM private_card_purchases pc
  JOIN private_cards c ON c.id = pc.card_id
  WHERE c.creator_id = p_creator_id
    AND pc.created_at >= p_period_start
    AND pc.created_at < p_period_end + INTERVAL '1 day';

  v_gross_dt := v_tip_total_dt + v_card_total_dt;
  v_dt_revenue_krw := v_gross_dt;

  -- 3. KRW 수익: 펀딩
  SELECT
    COUNT(DISTINCT fp2.campaign_id),
    COUNT(*),
    COALESCE(SUM(fp2.amount_krw), 0)
  INTO v_funding_campaign_count, v_funding_pledge_count, v_funding_total_krw
  FROM funding_payments fp2
  WHERE fp2.status = 'paid'
    AND fp2.campaign_id IN (
      SELECT id FROM funding_campaigns WHERE creator_id = p_creator_id
    )
    AND fp2.paid_at >= p_period_start
    AND fp2.paid_at < p_period_end + INTERVAL '1 day';

  -- 4. 합산
  v_total_revenue_krw := v_dt_revenue_krw + v_funding_total_krw;

  gross_dt := v_gross_dt;
  gross_krw := v_total_revenue_krw;
  platform_fee_krw := FLOOR(v_total_revenue_krw * p_platform_fee_rate);
  withholding_tax_krw := FLOOR((v_total_revenue_krw - platform_fee_krw) * p_withholding_tax_rate);
  net_krw := v_total_revenue_krw - platform_fee_krw - withholding_tax_krw;
  tip_count := v_tip_count;
  tip_total_dt := v_tip_total_dt;
  private_card_count := v_card_count;
  private_card_total_dt := v_card_total_dt;
  funding_campaign_count := v_funding_campaign_count;
  funding_pledge_count := v_funding_pledge_count;
  funding_total_krw := v_funding_total_krw;

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- 7. 권한 부여
-- ============================================
GRANT SELECT ON income_tax_rates TO authenticated;
GRANT ALL ON settlement_statements TO authenticated;
