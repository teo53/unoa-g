-- ============================================
-- UNO A - Creator Payout Accounts Schema (정산 계좌 분리)
-- Version: 1.0.0
--
-- SECURITY:
-- - 정산 계좌 정보를 creator_profiles에서 분리하여 별도 테이블로 관리
-- - 모든 민감 정보(계좌번호, 예금주명)는 AES-256-GCM으로 암호화
-- - RLS로 본인만 조회 가능, 삽입/수정은 service_role만 가능
-- ============================================

-- ============================================
-- 1. CREATOR_PAYOUT_ACCOUNTS TABLE (정산 계좌 정보)
-- ============================================
CREATE TABLE IF NOT EXISTS public.creator_payout_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 은행 정보 (비암호화 - 공개 정보)
  bank_code TEXT NOT NULL,            -- 은행 코드 (020: 우리, 088: 신한, etc.)
  bank_name TEXT NOT NULL,            -- 은행명

  -- 암호화된 계좌 정보
  account_holder_name_encrypted TEXT NOT NULL,  -- 예금주명 (암호화)
  account_number_encrypted TEXT NOT NULL,       -- 계좌번호 (암호화)

  -- 사업자 정보 (선택, 암호화)
  business_registration_number_encrypted TEXT,  -- 사업자등록번호 (암호화)
  resident_registration_number_encrypted TEXT,  -- 주민등록번호 (암호화, 세금 목적)

  -- 검증 상태
  is_verified BOOLEAN DEFAULT false,  -- 1원 인증 완료 여부
  verified_at TIMESTAMPTZ,            -- 검증 완료 시점
  verification_method TEXT,           -- 검증 방법 (1won, manual, portone)

  -- 세금 설정
  tax_type TEXT DEFAULT 'individual' CHECK (tax_type IN ('individual', 'business')),
  withholding_tax_rate NUMERIC DEFAULT 0.033,  -- 기본 3.3% (프리랜서)

  -- 상태
  is_active BOOLEAN DEFAULT true,     -- 활성 계좌 여부 (여러 계좌 중 선택)
  is_primary BOOLEAN DEFAULT true,    -- 대표 정산 계좌

  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 유니크 제약 (creator당 하나의 primary 계좌)
CREATE UNIQUE INDEX IF NOT EXISTS idx_creator_payout_primary
  ON creator_payout_accounts(creator_id)
  WHERE is_primary = true AND is_active = true;

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_creator_payout_accounts_creator ON creator_payout_accounts(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_payout_accounts_bank ON creator_payout_accounts(bank_code);
CREATE INDEX IF NOT EXISTS idx_creator_payout_accounts_verified ON creator_payout_accounts(is_verified);

-- ============================================
-- 2. RLS POLICIES
-- ============================================
ALTER TABLE creator_payout_accounts ENABLE ROW LEVEL SECURITY;

-- 크리에이터는 자신의 계좌 정보만 조회 가능
CREATE POLICY "Creators can view own payout accounts"
  ON creator_payout_accounts FOR SELECT
  USING (creator_id = auth.uid());

-- 삽입/수정은 service_role만 가능 (Edge Function에서만)
-- 보안상 클라이언트에서 직접 계좌 정보 수정 불가

-- ============================================
-- 3. TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION update_creator_payout_account_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_creator_payout_accounts_updated_at ON creator_payout_accounts;
CREATE TRIGGER update_creator_payout_accounts_updated_at
  BEFORE UPDATE ON creator_payout_accounts
  FOR EACH ROW
  EXECUTE FUNCTION update_creator_payout_account_updated_at();

-- is_primary 설정 시 다른 계좌의 is_primary를 false로
CREATE OR REPLACE FUNCTION handle_primary_payout_account()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_primary = true THEN
    UPDATE creator_payout_accounts
    SET is_primary = false, updated_at = now()
    WHERE creator_id = NEW.creator_id
      AND id != NEW.id
      AND is_primary = true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_primary_payout_account_set ON creator_payout_accounts;
CREATE TRIGGER on_primary_payout_account_set
  BEFORE INSERT OR UPDATE OF is_primary ON creator_payout_accounts
  FOR EACH ROW
  WHEN (NEW.is_primary = true)
  EXECUTE FUNCTION handle_primary_payout_account();

-- ============================================
-- 4. HELPER FUNCTIONS
-- ============================================

-- 크리에이터의 대표 정산 계좌 조회
CREATE OR REPLACE FUNCTION public.get_primary_payout_account(p_creator_id UUID)
RETURNS creator_payout_accounts AS $$
  SELECT * FROM creator_payout_accounts
  WHERE creator_id = p_creator_id
    AND is_primary = true
    AND is_active = true
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 정산 가능 여부 확인 (계좌 검증 완료 확인)
CREATE OR REPLACE FUNCTION public.can_request_payout(p_creator_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM creator_payout_accounts
    WHERE creator_id = p_creator_id
      AND is_primary = true
      AND is_active = true
      AND is_verified = true
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 권한 부여
GRANT EXECUTE ON FUNCTION public.get_primary_payout_account(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_request_payout(UUID) TO authenticated;

-- ============================================
-- 5. BANK CODES REFERENCE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.bank_codes (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  name_en TEXT,
  is_active BOOLEAN DEFAULT true
);

-- 한국 주요 은행 코드 (금융결제원 기준)
INSERT INTO bank_codes (code, name, name_en) VALUES
  ('002', 'KDB산업은행', 'KDB'),
  ('003', 'IBK기업은행', 'IBK'),
  ('004', 'KB국민은행', 'KB'),
  ('007', '수협은행', 'Suhyup'),
  ('011', 'NH농협은행', 'NH'),
  ('012', '농협중앙회', 'NH Central'),
  ('020', '우리은행', 'Woori'),
  ('023', 'SC제일은행', 'SC'),
  ('027', '한국씨티은행', 'Citi'),
  ('031', '대구은행', 'Daegu'),
  ('032', '부산은행', 'Busan'),
  ('034', '광주은행', 'Gwangju'),
  ('035', '제주은행', 'Jeju'),
  ('037', '전북은행', 'Jeonbuk'),
  ('039', '경남은행', 'Gyeongnam'),
  ('045', '새마을금고', 'KFCC'),
  ('048', '신협', 'CU'),
  ('071', '우체국', 'Post'),
  ('081', '하나은행', 'Hana'),
  ('088', '신한은행', 'Shinhan'),
  ('089', '케이뱅크', 'K-Bank'),
  ('090', '카카오뱅크', 'Kakao'),
  ('092', '토스뱅크', 'Toss')
ON CONFLICT (code) DO NOTHING;

-- 은행 코드 조회용 RLS (모두 조회 가능)
ALTER TABLE bank_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view bank codes" ON bank_codes;
CREATE POLICY "Anyone can view bank codes"
  ON bank_codes FOR SELECT
  USING (true);

-- ============================================
-- 6. PAYOUT ACCOUNT VERIFICATION LOGS (1원 인증 등)
-- ============================================
CREATE TABLE IF NOT EXISTS public.payout_account_verification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_account_id UUID NOT NULL REFERENCES creator_payout_accounts(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  verification_method TEXT NOT NULL,   -- '1won', 'manual', 'portone'
  verification_code TEXT,              -- 1원 인증 시 입금자명에 포함된 코드
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed', 'expired')),
  error_message TEXT,

  expires_at TIMESTAMPTZ,              -- 인증 만료 시간 (1원 인증은 보통 10분)
  verified_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payout_verification_account ON payout_account_verification_logs(payout_account_id);
CREATE INDEX IF NOT EXISTS idx_payout_verification_status ON payout_account_verification_logs(status);

ALTER TABLE payout_account_verification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view own verification logs"
  ON payout_account_verification_logs FOR SELECT
  USING (creator_id = auth.uid());

-- ============================================
-- 7. MIGRATE EXISTING DATA (기존 creator_profiles 데이터 마이그레이션)
-- ============================================
-- 주의: 실제 운영 환경에서는 암호화 로직을 Edge Function에서 실행해야 함
-- 이 SQL은 암호화되지 않은 데이터가 있을 경우의 마이그레이션 가이드

-- 기존 creator_profiles에 평문 계좌정보가 있는 경우 경고
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM creator_profiles
    WHERE bank_account_number IS NOT NULL
       OR account_holder_name IS NOT NULL
  ) THEN
    RAISE NOTICE 'WARNING: creator_profiles에 평문 계좌 정보가 있습니다. Edge Function을 통해 암호화 마이그레이션이 필요합니다.';
  END IF;
END;
$$;

COMMENT ON TABLE creator_payout_accounts IS '크리에이터 정산 계좌 정보 - 민감 데이터 암호화됨';
COMMENT ON TABLE bank_codes IS '한국 은행 코드 참조 테이블';
COMMENT ON TABLE payout_account_verification_logs IS '계좌 인증(1원 인증 등) 로그';
