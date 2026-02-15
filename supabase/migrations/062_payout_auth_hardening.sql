-- ============================================
-- Migration: 062_payout_auth_hardening.sql
-- Purpose: Add auth.uid() checks to payout-related functions
--
-- Context:
-- Migration 061 added auth checks to request_payout and get_creator_tax_info,
-- but three other payout functions still lack auth checks:
-- 1. calculate_creator_payout - returns sensitive financial data
-- 2. get_primary_payout_account - returns bank account info
-- 3. can_request_payout - returns payout eligibility status
--
-- All three are GRANTED to authenticated users but allow any authenticated
-- user to query another creator's sensitive financial information.
--
-- Changes:
-- - Add auth.uid() checks with NULL guard (allows service_role calls)
-- - Convert get_primary_payout_account from SQL to plpgsql to add auth check
-- - Keep all function signatures and logic identical
-- - Pattern: IF auth.uid() IS NOT NULL AND auth.uid() != p_creator_id THEN RAISE EXCEPTION
-- ============================================

BEGIN;

-- ============================================
-- 1. calculate_creator_payout - Add auth check
-- ============================================
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
  -- Auth check: Only allow creator to view their own payout calculation
  -- NULL guard allows service_role calls (where auth.uid() is null)
  IF auth.uid() IS NOT NULL AND auth.uid() != p_creator_id THEN
    RAISE EXCEPTION 'Access denied: cannot calculate payout for another creator';
  END IF;

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
-- 2. get_primary_payout_account - Convert to plpgsql and add auth check
-- ============================================
CREATE OR REPLACE FUNCTION public.get_primary_payout_account(p_creator_id UUID)
RETURNS creator_payout_accounts AS $$
DECLARE
  v_account creator_payout_accounts;
BEGIN
  -- Auth check: Only allow creator to view their own payout account
  -- NULL guard allows service_role calls
  IF auth.uid() IS NOT NULL AND auth.uid() != p_creator_id THEN
    RAISE EXCEPTION 'Access denied: cannot view another creator''s payout account';
  END IF;

  SELECT * INTO v_account
  FROM creator_payout_accounts
  WHERE creator_id = p_creator_id
    AND is_primary = true
    AND is_active = true
  LIMIT 1;

  RETURN v_account;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================
-- 3. can_request_payout - Add auth check
-- ============================================
CREATE OR REPLACE FUNCTION public.can_request_payout(p_creator_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- Auth check: Only allow creator to check their own payout eligibility
  -- NULL guard allows service_role calls
  IF auth.uid() IS NOT NULL AND auth.uid() != p_creator_id THEN
    RAISE EXCEPTION 'Access denied: cannot check another creator''s payout eligibility';
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM creator_payout_accounts
    WHERE creator_id = p_creator_id
      AND is_primary = true
      AND is_active = true
      AND is_verified = true
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMIT;
