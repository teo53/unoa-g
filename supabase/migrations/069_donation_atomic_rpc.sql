-- =====================================================
-- Migration: 069_donation_atomic_rpc.sql
-- WI-1B: Atomic donation RPC with idempotency
-- Purpose: Replace non-atomic 3-step donation in
--          wallet_provider.dart with single atomic RPC
-- Rules: auth.uid() internal extraction (#7),
--         SET search_path = public (#6)
-- =====================================================

-- 1) Add idempotency_key column to dt_donations
ALTER TABLE dt_donations
  ADD COLUMN IF NOT EXISTS idempotency_key TEXT;

-- Create unique index for idempotency enforcement
CREATE UNIQUE INDEX IF NOT EXISTS idx_donations_idempotency_key
  ON dt_donations(idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- 2) Create atomic donation processing function
CREATE OR REPLACE FUNCTION process_donation_atomic(
  p_channel_id UUID,
  p_creator_id UUID,
  p_amount_dt INTEGER,
  p_idempotency_key TEXT,
  p_message_id UUID DEFAULT NULL,
  p_is_anonymous BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_wallet RECORD;
  v_creator_share INTEGER;
  v_platform_fee INTEGER;
  v_donation_id UUID;
  v_new_balance INTEGER;
BEGIN
  -- Extract authenticated user (Rule #7: no from_user_id parameter)
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Idempotency check: if donation with this key already exists, return success
  IF EXISTS (
    SELECT 1 FROM dt_donations
    WHERE idempotency_key = p_idempotency_key
  ) THEN
    RETURN jsonb_build_object(
      'success', true,
      'already_processed', true,
      'idempotency_key', p_idempotency_key
    );
  END IF;

  -- Validate amount
  IF p_amount_dt <= 0 THEN
    RAISE EXCEPTION 'Invalid donation amount: %', p_amount_dt;
  END IF;

  -- Get and lock wallet (SELECT FOR UPDATE)
  SELECT id, balance_dt, lifetime_spent_dt
  INTO v_wallet
  FROM wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_wallet IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user';
  END IF;

  -- Check sufficient balance
  IF v_wallet.balance_dt < p_amount_dt THEN
    RAISE EXCEPTION 'Insufficient balance: have %, need %',
      v_wallet.balance_dt, p_amount_dt;
  END IF;

  -- Calculate revenue split (20% platform, 80% creator)
  v_platform_fee := FLOOR(p_amount_dt * 0.20);
  v_creator_share := p_amount_dt - v_platform_fee;

  -- 1. Create donation record
  INSERT INTO dt_donations (
    from_user_id,
    to_channel_id,
    to_creator_id,
    amount_dt,
    message_id,
    is_anonymous,
    creator_share_dt,
    platform_fee_dt,
    idempotency_key
  ) VALUES (
    v_user_id,
    p_channel_id,
    p_creator_id,
    p_amount_dt,
    p_message_id,
    p_is_anonymous,
    v_creator_share,
    v_platform_fee,
    p_idempotency_key
  )
  RETURNING id INTO v_donation_id;

  -- 2. Create ledger entry
  INSERT INTO ledger_entries (
    idempotency_key,
    from_wallet_id,
    amount_dt,
    entry_type,
    reference_type,
    reference_id,
    description,
    status,
    created_at
  ) VALUES (
    p_idempotency_key,
    v_wallet.id,
    p_amount_dt,
    'tip',
    'donation',
    v_donation_id,
    format('후원: %s DT', p_amount_dt),
    'completed',
    NOW()
  );

  -- 3. Deduct from wallet balance
  UPDATE wallets
  SET
    balance_dt = balance_dt - p_amount_dt,
    lifetime_spent_dt = lifetime_spent_dt + p_amount_dt,
    updated_at = NOW()
  WHERE user_id = v_user_id
  RETURNING balance_dt INTO v_new_balance;

  -- Safety: should never happen due to prior check, but guard anyway
  IF v_new_balance < 0 THEN
    RAISE EXCEPTION 'Donation would result in negative balance';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'donation_id', v_donation_id,
    'amount_dt', p_amount_dt,
    'creator_share', v_creator_share,
    'platform_fee', v_platform_fee,
    'new_balance', v_new_balance
  );
END;
$$;

-- Grant to authenticated users (Rule #6: auth.uid() used internally)
GRANT EXECUTE ON FUNCTION process_donation_atomic TO authenticated;

COMMENT ON FUNCTION process_donation_atomic IS
'Atomically processes a donation: creates donation record, ledger entry, and deducts wallet balance.
All operations succeed or fail together. Uses auth.uid() internally (Rule #7).
Idempotency via p_idempotency_key prevents double-processing.';
