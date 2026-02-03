-- ============================================
-- UNO A - Payouts & Tax Schema (Korea-first)
-- Version: 1.1.0
-- ============================================

-- ============================================
-- 1. PAYOUT REQUESTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id),
  creator_profile_id UUID REFERENCES creator_profiles(id),

  -- Period
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,

  -- Amounts (in Korean Won)
  gross_dt INT NOT NULL, -- Total DT earned
  gross_krw INT NOT NULL, -- 1 DT = 100 KRW

  -- Deductions
  platform_fee_rate NUMERIC DEFAULT 0.20, -- 20%
  platform_fee_krw INT NOT NULL,
  payment_processing_fee_krw INT DEFAULT 0, -- Payment gateway fees

  -- Tax (Korea: 3.3% withholding for "기타소득")
  -- 기타소득세 3% + 지방소득세 0.3% = 3.3%
  withholding_tax_rate NUMERIC DEFAULT 0.033,
  withholding_tax_krw INT NOT NULL,

  -- Final amount
  net_krw INT NOT NULL,

  -- Bank info (snapshot at time of payout)
  bank_code TEXT NOT NULL,
  bank_name TEXT,
  bank_account_last4 TEXT NOT NULL,
  account_holder_name TEXT NOT NULL,

  -- State machine
  status TEXT DEFAULT 'pending_review' CHECK (status IN (
    'pending_review',  -- Awaiting admin approval
    'approved',        -- Approved, awaiting processing
    'processing',      -- Being processed by bank
    'paid',            -- Successfully paid
    'failed',          -- Bank transfer failed
    'cancelled',       -- Cancelled by admin/creator
    'on_hold'          -- On hold for review
  )),

  -- Review
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,

  -- Bank transfer tracking
  bank_transfer_id TEXT,
  bank_transfer_at TIMESTAMPTZ,
  bank_error_message TEXT,
  retry_count INT DEFAULT 0,

  -- Settlement statement
  statement_pdf_url TEXT,
  statement_generated_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  requested_at TIMESTAMPTZ DEFAULT now(),
  paid_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_payouts_creator ON payouts(creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payouts_period ON payouts(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_payouts_pending ON payouts(status)
  WHERE status IN ('pending_review', 'approved', 'processing');

-- ============================================
-- 2. PAYOUT LINE ITEMS (detail breakdown)
-- ============================================
CREATE TABLE IF NOT EXISTS public.payout_line_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_id UUID NOT NULL REFERENCES payouts(id) ON DELETE CASCADE,

  item_type TEXT NOT NULL CHECK (item_type IN (
    'tip',           -- DT Donations/Tips
    'paid_reply',    -- Paid reply tokens
    'private_card',  -- Private card sales
    'chat_ticket',   -- Chat ticket subscription
    'challenge'      -- Challenge rewards
  )),

  item_count INT NOT NULL,
  gross_dt INT NOT NULL,
  gross_krw INT NOT NULL,

  -- Reference IDs for audit
  reference_ids UUID[] DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payout_items_payout ON payout_line_items(payout_id);

-- ============================================
-- 3. PAYOUT STATUS LOG (audit trail)
-- ============================================
CREATE TABLE IF NOT EXISTS public.payout_status_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_id UUID NOT NULL REFERENCES payouts(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT NOT NULL,
  changed_by UUID REFERENCES auth.users(id),
  reason TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payout_log_payout ON payout_status_log(payout_id, created_at);

-- ============================================
-- 4. PAYOUT SETTINGS (per creator)
-- ============================================
CREATE TABLE IF NOT EXISTS public.payout_settings (
  creator_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Payout schedule
  auto_payout_enabled BOOLEAN DEFAULT true,
  payout_day_of_month INT DEFAULT 10 CHECK (payout_day_of_month BETWEEN 1 AND 28),
  minimum_payout_krw INT DEFAULT 10000, -- 10,000 KRW minimum

  -- Tax settings
  tax_type TEXT DEFAULT 'individual' CHECK (tax_type IN ('individual', 'business')),
  withholding_tax_rate NUMERIC DEFAULT 0.033,

  -- Notifications
  notify_payout_ready BOOLEAN DEFAULT true,
  notify_payout_complete BOOLEAN DEFAULT true,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 5. BANK CODES (Korean banks)
-- ============================================
CREATE TABLE IF NOT EXISTS public.bank_codes (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  name_en TEXT,
  is_active BOOLEAN DEFAULT true
);

-- Insert Korean bank codes
INSERT INTO bank_codes (code, name, name_en) VALUES
  ('004', 'KB국민은행', 'KB Kookmin Bank'),
  ('011', 'NH농협은행', 'NH NongHyup Bank'),
  ('020', '우리은행', 'Woori Bank'),
  ('023', 'SC제일은행', 'SC First Bank'),
  ('027', '한국씨티은행', 'Citibank Korea'),
  ('031', '대구은행', 'DGB Daegu Bank'),
  ('032', '부산은행', 'BNK Busan Bank'),
  ('034', '광주은행', 'Kwangju Bank'),
  ('035', '제주은행', 'Jeju Bank'),
  ('037', '전북은행', 'JB Bank'),
  ('039', '경남은행', 'BNK Kyongnam Bank'),
  ('045', '새마을금고', 'MG Community Credit'),
  ('048', '신용협동조합', 'KFCC'),
  ('050', '상호저축은행', 'Mutual Savings Bank'),
  ('064', '산림조합', 'NFCF'),
  ('071', '우체국', 'Korea Post'),
  ('081', '하나은행', 'Hana Bank'),
  ('088', '신한은행', 'Shinhan Bank'),
  ('089', '케이뱅크', 'K-Bank'),
  ('090', '카카오뱅크', 'Kakao Bank'),
  ('092', '토스뱅크', 'Toss Bank')
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en;

-- ============================================
-- 6. RLS POLICIES
-- ============================================
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_status_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_codes ENABLE ROW LEVEL SECURITY;

-- Payouts
CREATE POLICY "Creators can view own payouts"
  ON payouts FOR SELECT
  USING (creator_id = auth.uid());

CREATE POLICY "Admins can manage all payouts"
  ON payouts FOR ALL
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Payout Line Items
CREATE POLICY "Creators can view own payout items"
  ON payout_line_items FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM payouts p WHERE p.id = payout_line_items.payout_id AND p.creator_id = auth.uid())
  );

-- Payout Status Log
CREATE POLICY "Creators can view own payout logs"
  ON payout_status_log FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM payouts p WHERE p.id = payout_status_log.payout_id AND p.creator_id = auth.uid())
  );

-- Payout Settings
CREATE POLICY "Creators can manage own payout settings"
  ON payout_settings FOR ALL
  USING (creator_id = auth.uid());

-- Bank Codes (public read)
CREATE POLICY "Anyone can view bank codes"
  ON bank_codes FOR SELECT
  USING (true);

-- ============================================
-- 7. TRIGGERS
-- ============================================

-- Log payout status changes
CREATE OR REPLACE FUNCTION public.log_payout_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO payout_status_log (payout_id, from_status, to_status, changed_by, metadata)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid(), jsonb_build_object(
      'review_notes', NEW.review_notes,
      'bank_error', NEW.bank_error_message
    ));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_payout_status_change ON payouts;
CREATE TRIGGER on_payout_status_change
  AFTER UPDATE ON payouts
  FOR EACH ROW
  EXECUTE FUNCTION public.log_payout_status_change();

-- Update updated_at
DROP TRIGGER IF EXISTS update_payouts_updated_at ON payouts;
CREATE TRIGGER update_payouts_updated_at
  BEFORE UPDATE ON payouts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- 8. HELPER FUNCTIONS
-- ============================================

-- Calculate payout for a creator and period
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
  private_card_total_dt INT
) AS $$
DECLARE
  v_gross_dt INT := 0;
  v_tip_count INT := 0;
  v_tip_total_dt INT := 0;
  v_card_count INT := 0;
  v_card_total_dt INT := 0;
BEGIN
  -- Sum tips/donations
  SELECT COUNT(*), COALESCE(SUM(creator_share_dt), 0)
  INTO v_tip_count, v_tip_total_dt
  FROM dt_donations
  WHERE to_creator_id = p_creator_id
    AND created_at >= p_period_start
    AND created_at < p_period_end + INTERVAL '1 day';

  -- Sum private card sales
  SELECT COUNT(*), COALESCE(SUM(pc.price_paid_dt * (1 - p_platform_fee_rate)), 0)::INT
  INTO v_card_count, v_card_total_dt
  FROM private_card_purchases pc
  JOIN private_cards c ON c.id = pc.card_id
  WHERE c.creator_id = p_creator_id
    AND pc.created_at >= p_period_start
    AND pc.created_at < p_period_end + INTERVAL '1 day';

  v_gross_dt := v_tip_total_dt + v_card_total_dt;

  gross_dt := v_gross_dt;
  gross_krw := v_gross_dt * 100; -- 1 DT = 100 KRW
  platform_fee_krw := FLOOR(gross_krw * p_platform_fee_rate);
  withholding_tax_krw := FLOOR((gross_krw - platform_fee_krw) * p_withholding_tax_rate);
  net_krw := gross_krw - platform_fee_krw - withholding_tax_krw;
  tip_count := v_tip_count;
  tip_total_dt := v_tip_total_dt;
  private_card_count := v_card_count;
  private_card_total_dt := v_card_total_dt;

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql STABLE;

-- Request payout
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
  -- Get creator profile
  SELECT * INTO v_creator FROM creator_profiles WHERE user_id = p_creator_id;
  IF v_creator IS NULL THEN
    RAISE EXCEPTION 'Creator profile not found';
  END IF;

  IF NOT v_creator.payout_verified THEN
    RAISE EXCEPTION 'Payout info not verified';
  END IF;

  -- Get settings
  SELECT * INTO v_settings FROM payout_settings WHERE creator_id = p_creator_id;

  -- Calculate payout
  SELECT * INTO v_calc FROM calculate_creator_payout(
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
    SELECT 1 FROM payouts
    WHERE creator_id = p_creator_id
      AND period_start = p_period_start
      AND period_end = p_period_end
      AND status NOT IN ('cancelled', 'failed')
  ) THEN
    RAISE EXCEPTION 'Payout already exists for this period';
  END IF;

  -- Create payout
  INSERT INTO payouts (
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
    (SELECT name FROM bank_codes WHERE code = v_creator.bank_code),
    RIGHT(v_creator.bank_account_number, 4),
    v_creator.account_holder_name,
    'pending_review'
  ) RETURNING * INTO v_payout;

  -- Create line items
  IF v_calc.tip_count > 0 THEN
    INSERT INTO payout_line_items (payout_id, item_type, item_count, gross_dt, gross_krw)
    VALUES (v_payout.id, 'tip', v_calc.tip_count, v_calc.tip_total_dt, v_calc.tip_total_dt * 100);
  END IF;

  IF v_calc.private_card_count > 0 THEN
    INSERT INTO payout_line_items (payout_id, item_type, item_count, gross_dt, gross_krw)
    VALUES (v_payout.id, 'private_card', v_calc.private_card_count, v_calc.private_card_total_dt, v_calc.private_card_total_dt * 100);
  END IF;

  RETURN v_payout;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Approve payout (admin only)
CREATE OR REPLACE FUNCTION public.approve_payout(p_payout_id UUID, p_notes TEXT DEFAULT NULL)
RETURNS payouts AS $$
DECLARE
  v_payout payouts;
BEGIN
  -- Check admin role
  IF NOT EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Admin role required';
  END IF;

  UPDATE payouts SET
    status = 'approved',
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_notes = p_notes,
    updated_at = now()
  WHERE id = p_payout_id AND status = 'pending_review'
  RETURNING * INTO v_payout;

  IF v_payout IS NULL THEN
    RAISE EXCEPTION 'Payout not found or not in pending_review status';
  END IF;

  RETURN v_payout;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
