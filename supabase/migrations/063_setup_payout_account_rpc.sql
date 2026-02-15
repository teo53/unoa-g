-- =====================================================
-- Migration: 063_setup_payout_account_rpc.sql
-- Purpose: Secure RPC for creating/updating payout accounts
-- Description:
--   Encrypts bank account info server-side using encrypt_sensitive()
--   and stores into creator_payout_accounts.
--   Also updates creator_profiles.bank_account_last4 for display.
--
-- SECURITY:
--   - Encryption happens inside the DB function (SECURITY DEFINER)
--   - Client never sees or handles encryption keys
--   - Only authenticated creators can call this for themselves
-- =====================================================

CREATE OR REPLACE FUNCTION public.setup_payout_account(
  p_bank_code TEXT,
  p_bank_name TEXT,
  p_account_holder_name TEXT,
  p_account_number TEXT,
  p_tax_type TEXT DEFAULT 'individual'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_account_id UUID;
  v_last4 TEXT;
  v_holder_encrypted TEXT;
  v_number_encrypted TEXT;
BEGIN
  -- Auth check
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  -- Verify user is a creator
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = v_user_id AND role IN ('creator', 'creator_manager')
  ) THEN
    RAISE EXCEPTION 'creator_role_required';
  END IF;

  -- Validate inputs
  IF p_bank_code IS NULL OR p_bank_code = '' THEN
    RAISE EXCEPTION 'bank_code_required';
  END IF;
  IF p_account_number IS NULL OR length(p_account_number) < 8 THEN
    RAISE EXCEPTION 'invalid_account_number';
  END IF;
  IF p_account_holder_name IS NULL OR p_account_holder_name = '' THEN
    RAISE EXCEPTION 'account_holder_name_required';
  END IF;
  IF p_tax_type NOT IN ('individual', 'business') THEN
    RAISE EXCEPTION 'invalid_tax_type';
  END IF;

  -- Extract last 4 digits for display
  v_last4 := right(p_account_number, 4);

  -- Encrypt sensitive data
  v_holder_encrypted := encrypt_sensitive(p_account_holder_name);
  v_number_encrypted := encrypt_sensitive(p_account_number);

  -- Upsert into creator_payout_accounts
  INSERT INTO creator_payout_accounts (
    creator_id,
    bank_code,
    bank_name,
    account_holder_name_encrypted,
    account_number_encrypted,
    tax_type,
    is_primary,
    is_active
  ) VALUES (
    v_user_id,
    p_bank_code,
    p_bank_name,
    v_holder_encrypted,
    v_number_encrypted,
    p_tax_type,
    true,
    true
  )
  ON CONFLICT (creator_id) WHERE is_primary = true AND is_active = true
  DO UPDATE SET
    bank_code = EXCLUDED.bank_code,
    bank_name = EXCLUDED.bank_name,
    account_holder_name_encrypted = EXCLUDED.account_holder_name_encrypted,
    account_number_encrypted = EXCLUDED.account_number_encrypted,
    tax_type = EXCLUDED.tax_type,
    updated_at = now()
  RETURNING id INTO v_account_id;

  -- Update creator_profiles with display-safe info only
  UPDATE creator_profiles SET
    bank_code = p_bank_code,
    bank_account_last4 = v_last4,
    account_holder_name = p_account_holder_name,
    updated_at = now()
  WHERE user_id = v_user_id;

  RETURN json_build_object(
    'success', true,
    'account_id', v_account_id,
    'bank_code', p_bank_code,
    'bank_name', p_bank_name,
    'last4', v_last4
  );
END;
$$;

-- Grant to authenticated users
GRANT EXECUTE ON FUNCTION public.setup_payout_account(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

COMMENT ON FUNCTION public.setup_payout_account IS '크리에이터 정산 계좌 등록/수정 - 서버 사이드 암호화 적용';
