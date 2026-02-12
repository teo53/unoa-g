-- =====================================================
-- Migration 048: 세무/법무 컴플라이언스 수정
--
-- 포함 사항:
--   1. decrement_campaign_amount RPC (펀딩 환불 webhook 필수)
--   2. DT 구매 VAT 추적 컬럼 추가
--   3. 비거주자 원천징수 22% 지원
--   4. 컴플라이언스 인프라 테이블
--      - vat_reconciliation (월별 VAT 시점 차이 조정)
--      - breakage_estimates (분기별 미사용 DT 수익인식)
--      - prepaid_balance_snapshots (일별 선불잔액 적립 모니터링)
--      - compliance_disclosures (고지 의무 이행 추적)
--   5. settlement_statements dt_to_krw_rate DEFAULT 수정
-- =====================================================

-- =====================================================
-- 1. decrement_campaign_amount RPC
-- =====================================================

CREATE OR REPLACE FUNCTION public.decrement_campaign_amount(
  p_campaign_id UUID,
  p_amount_krw INT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_amount_krw <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive: %', p_amount_krw;
  END IF;

  UPDATE funding_campaigns SET
    current_amount_krw = GREATEST(current_amount_krw - p_amount_krw, 0),
    backer_count = GREATEST(backer_count - 1, 0),
    updated_at = now()
  WHERE id = p_campaign_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Campaign not found: %', p_campaign_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.decrement_campaign_amount TO service_role;

COMMENT ON FUNCTION public.decrement_campaign_amount IS
  '펀딩 환불 시 캠페인 현재 금액 및 후원자 수 차감. funding-payment-webhook에서 호출.';

-- =====================================================
-- 2. DT 구매 VAT 추적 컬럼
-- =====================================================

ALTER TABLE public.dt_purchases
  ADD COLUMN IF NOT EXISTS supply_amount_krw INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS vat_amount_krw INT DEFAULT 0;

COMMENT ON COLUMN public.dt_purchases.supply_amount_krw IS
  '공급가액 (VAT 제외). price_krw × 10/11 (원 미만 절사)';
COMMENT ON COLUMN public.dt_purchases.vat_amount_krw IS
  '부가가치세액 (10%). price_krw - supply_amount_krw';

-- 기존 paid 상태 레코드에 대해 VAT 역산 적용
UPDATE public.dt_purchases
SET supply_amount_krw = FLOOR(price_krw * 10.0 / 11),
    vat_amount_krw = price_krw - FLOOR(price_krw * 10.0 / 11)
WHERE supply_amount_krw = 0
  AND vat_amount_krw = 0
  AND price_krw > 0;

-- =====================================================
-- 3. 비거주자 원천징수 22% 지원
-- income_tax_rates 테이블의 기존 CHECK 제약조건은
-- 046에서 이미 삭제됨 (다양한 income_type 허용)
-- =====================================================

-- payout_settings 테이블 CHECK 제약조건 확장
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'payout_settings_income_type_check'
    AND table_name = 'payout_settings'
  ) THEN
    ALTER TABLE public.payout_settings
      DROP CONSTRAINT payout_settings_income_type_check;
  END IF;
END $$;

-- 비거주자 세율 레코드 삽입
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'income_tax_rates') THEN
    RAISE NOTICE 'income_tax_rates table does not exist, skipping non_resident insert';
    RETURN;
  END IF;

  -- label_ko 컬럼 존재 확인
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'income_tax_rates' AND column_name = 'label_ko'
  ) THEN
    RAISE NOTICE 'income_tax_rates.label_ko does not exist, skipping non_resident insert';
    RETURN;
  END IF;

  INSERT INTO public.income_tax_rates (
    income_type, label_ko, description_ko,
    tax_rate, income_tax_rate, local_tax_rate,
    requires_business_registration, display_order
  ) VALUES (
    'non_resident',
    '비거주자 (22%)',
    '비거주자 인적용역소득. 소득세 20% + 지방소득세 2%. 조세조약 적용 시 세율 변경 가능.',
    22.00, 20.00, 2.00,
    false, 4
  ) ON CONFLICT (income_type) DO UPDATE SET
    tax_rate = EXCLUDED.tax_rate,
    income_tax_rate = EXCLUDED.income_tax_rate,
    local_tax_rate = EXCLUDED.local_tax_rate,
    label_ko = EXCLUDED.label_ko,
    description_ko = EXCLUDED.description_ko;
END $$;

-- =====================================================
-- 4. settlement_statements dt_to_krw_rate DEFAULT 수정
-- =====================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'settlement_statements') THEN
    ALTER TABLE public.settlement_statements
      ALTER COLUMN dt_to_krw_rate SET DEFAULT 100.0;
  ELSE
    RAISE NOTICE 'settlement_statements table does not exist, skipping DEFAULT update';
  END IF;
END $$;

-- =====================================================
-- 5. 컴플라이언스 인프라 테이블
-- =====================================================

-- 5a. VAT 조정 테이블 (월별)
CREATE TABLE IF NOT EXISTS public.vat_reconciliation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  period TEXT NOT NULL,
  accounting_revenue_krw BIGINT NOT NULL,
  vat_revenue_krw BIGINT NOT NULL,
  timing_difference_krw BIGINT NOT NULL,
  explanation TEXT,
  reconciled_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT vat_period_unique UNIQUE (period)
);

ALTER TABLE public.vat_reconciliation ENABLE ROW LEVEL SECURITY;

-- 5b. 미사용 DT 수익인식 (분기별)
CREATE TABLE IF NOT EXISTS public.breakage_estimates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  period TEXT NOT NULL,
  total_dt_issued BIGINT NOT NULL,
  total_dt_redeemed BIGINT NOT NULL,
  historical_redemption_rate NUMERIC(8,6) NOT NULL,
  estimated_breakage_dt BIGINT NOT NULL,
  recognized_revenue_krw BIGINT NOT NULL,
  cumulative_revenue_krw BIGINT NOT NULL,
  adjustment_krw BIGINT DEFAULT 0,
  refundable_portion_krw BIGINT DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT breakage_period_unique UNIQUE (period)
);

ALTER TABLE public.breakage_estimates ENABLE ROW LEVEL SECURITY;

-- 5c. 선불잔액 100% 적립 스냅샷 (일별)
CREATE TABLE IF NOT EXISTS public.prepaid_balance_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  snapshot_date DATE NOT NULL,
  total_point_liability_krw BIGINT NOT NULL,
  trust_bank_balance_krw BIGINT NOT NULL,
  shortfall_krw BIGINT DEFAULT 0,
  is_compliant BOOLEAN NOT NULL,
  alert_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT snapshot_date_unique UNIQUE (snapshot_date)
);

ALTER TABLE public.prepaid_balance_snapshots ENABLE ROW LEVEL SECURITY;

-- 5d. 고지 의무 이행 추적
CREATE TABLE IF NOT EXISTS public.compliance_disclosures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  disclosure_type TEXT NOT NULL CHECK (disclosure_type IN (
    'INTERMEDIARY_NOTICE',
    'DARK_PATTERN_CHECK',
    'SUBSCRIPTION_RENEWAL',
    'PRICE_CHANGE_CONSENT',
    'VAT_TIMING_DISCLOSURE'
  )),
  target_page TEXT NOT NULL,
  disclosure_text TEXT,
  status TEXT DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'PENDING_REVIEW')),
  verified_at TIMESTAMPTZ,
  verified_by TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.compliance_disclosures ENABLE ROW LEVEL SECURITY;

-- 초기 고지 의무 레코드 삽입
INSERT INTO public.compliance_disclosures (disclosure_type, target_page, disclosure_text, status) VALUES
  ('INTERMEDIARY_NOTICE', '/funding', '[UNO A]는 [크라우드펀딩] 거래의 통신판매중개자로서 당사자가 아니며, 해당 거래에 대한 책임은 각 크리에이터에게 있습니다.', 'ACTIVE'),
  ('INTERMEDIARY_NOTICE', '/funding/:campaignId', '[UNO A]는 [크라우드펀딩] 거래의 통신판매중개자로서 당사자가 아니며, 해당 거래에 대한 책임은 각 크리에이터에게 있습니다.', 'ACTIVE'),
  ('INTERMEDIARY_NOTICE', '/funding/checkout', '[UNO A]는 [크라우드펀딩] 거래의 통신판매중개자로서 당사자가 아니며, 해당 거래에 대한 책임은 각 크리에이터에게 있습니다.', 'ACTIVE'),
  ('INTERMEDIARY_NOTICE', '/funding/tier-select', '[UNO A]는 [크라우드펀딩] 거래의 통신판매중개자로서 당사자가 아니며, 해당 거래에 대한 책임은 각 크리에이터에게 있습니다.', 'ACTIVE')
ON CONFLICT DO NOTHING;

-- =====================================================
-- RLS Policies (admin only for compliance tables)
-- =====================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'service_role_vat_reconciliation') THEN
    CREATE POLICY "service_role_vat_reconciliation" ON public.vat_reconciliation
      FOR ALL TO service_role USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'service_role_breakage_estimates') THEN
    CREATE POLICY "service_role_breakage_estimates" ON public.breakage_estimates
      FOR ALL TO service_role USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'service_role_prepaid_snapshots') THEN
    CREATE POLICY "service_role_prepaid_snapshots" ON public.prepaid_balance_snapshots
      FOR ALL TO service_role USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'service_role_compliance') THEN
    CREATE POLICY "service_role_compliance" ON public.compliance_disclosures
      FOR ALL TO service_role USING (true) WITH CHECK (true);
  END IF;
END $$;
