-- =====================================================
-- Migration: 061_payout_tax_auth_checks.sql
-- Purpose: Add auth.uid() checks to request_payout and get_creator_tax_info
-- Security: Prevents any authenticated user from accessing other creators' data
--
-- 문제:
--   request_payout: SECURITY DEFINER이지만 p_creator_id와 auth.uid() 비교 없음
--     → 아무 authenticated 사용자가 다른 크리에이터의 정산 요청 가능
--   get_creator_tax_info: authenticated에 GRANT되어 있지만 본인 확인 없음
--     → 아무 authenticated 사용자가 다른 크리에이터의 세금 정보 조회 가능
--
-- 수정: 함수 앞단에 auth.uid() 확인 추가. 기존 로직은 동일.
-- =====================================================

BEGIN;

-- ============================================
-- 1. request_payout: 본인 확인 추가
-- ============================================
CREATE OR REPLACE FUNCTION public.request_payout(
  p_creator_id UUID,
  p_period_start DATE,
  p_period_end DATE
)
RETURNS payouts AS $$
DECLARE
  v_creator creator_profiles;
  v_calc RECORD;
  v_payout payouts;
  v_settings payout_settings;
BEGIN
  -- AUTH CHECK: 본인만 정산 요청 가능
  IF auth.uid() != p_creator_id THEN
    RAISE EXCEPTION 'Access denied: can only request payout for yourself';
  END IF;

  -- Get creator profile
  SELECT * INTO v_creator FROM public.creator_profiles WHERE user_id = p_creator_id;
  IF v_creator IS NULL THEN
    RAISE EXCEPTION 'Creator profile not found';
  END IF;

  IF NOT v_creator.payout_verified THEN
    RAISE EXCEPTION 'Payout info not verified';
  END IF;

  -- Get settings
  SELECT * INTO v_settings FROM public.payout_settings WHERE creator_id = p_creator_id;

  -- Calculate payout
  SELECT * INTO v_calc FROM public.calculate_creator_payout(
    p_creator_id,
    p_period_start,
    p_period_end,
    0.20,
    COALESCE(v_settings.withholding_tax_rate, v_creator.withholding_tax_rate, 0.033)
  );

  IF v_calc.net_krw < COALESCE(v_settings.minimum_payout_krw, 10000) THEN
    RAISE EXCEPTION 'Amount below minimum payout threshold';
  END IF;

  -- Check for existing payout in period
  IF EXISTS (
    SELECT 1 FROM public.payouts
    WHERE creator_id = p_creator_id
      AND period_start = p_period_start
      AND period_end = p_period_end
      AND status NOT IN ('cancelled', 'failed')
  ) THEN
    RAISE EXCEPTION 'Payout already exists for this period';
  END IF;

  -- Create payout
  INSERT INTO public.payouts (
    creator_id, creator_profile_id,
    period_start, period_end,
    gross_dt, gross_krw,
    platform_fee_rate, platform_fee_krw,
    withholding_tax_rate, withholding_tax_krw,
    net_krw,
    bank_code, bank_name, bank_account_last4, account_holder_name,
    status
  ) VALUES (
    p_creator_id, v_creator.id,
    p_period_start, p_period_end,
    v_calc.gross_dt, v_calc.gross_krw,
    0.20, v_calc.platform_fee_krw,
    COALESCE(v_settings.withholding_tax_rate, 0.033), v_calc.withholding_tax_krw,
    v_calc.net_krw,
    v_creator.bank_code,
    (SELECT name FROM public.bank_codes WHERE code = v_creator.bank_code),
    RIGHT(v_creator.bank_account_number, 4),
    v_creator.account_holder_name,
    'pending_review'
  ) RETURNING * INTO v_payout;

  -- Create line items
  IF v_calc.tip_count > 0 THEN
    INSERT INTO public.payout_line_items (payout_id, item_type, item_count, gross_dt, gross_krw)
    VALUES (v_payout.id, 'tip', v_calc.tip_count, v_calc.tip_total_dt, v_calc.tip_total_dt * 100);
  END IF;

  IF v_calc.private_card_count > 0 THEN
    INSERT INTO public.payout_line_items (payout_id, item_type, item_count, gross_dt, gross_krw)
    VALUES (v_payout.id, 'private_card', v_calc.private_card_count, v_calc.private_card_total_dt, v_calc.private_card_total_dt * 100);
  END IF;

  RETURN v_payout;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
   SET search_path = public;

-- ============================================
-- 2. get_creator_tax_info: 본인 또는 관리자 확인 추가
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
  -- AUTH CHECK: 본인 또는 관리자만 세금 정보 조회 가능
  IF auth.uid() != p_creator_id AND NOT public.is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Access denied: can only view your own tax info';
  END IF;

  -- 크리에이터 설정 조회
  SELECT ps.income_type, ps.withholding_tax_rate
  INTO v_income_type, v_withholding_rate
  FROM public.payout_settings ps WHERE ps.creator_id = p_creator_id;

  -- 소득유형 결정 (설정 > 기본값)
  income_type := COALESCE(v_income_type, 'business_income');

  -- 세율 조회
  SELECT itr.tax_rate, itr.income_tax_rate, itr.local_tax_rate, itr.label_ko
  INTO v_tax_rate_record
  FROM public.income_tax_rates itr
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
$$ LANGUAGE plpgsql STABLE
   SET search_path = public;

COMMIT;
