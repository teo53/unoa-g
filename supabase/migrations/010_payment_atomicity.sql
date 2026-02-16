-- =====================================================
-- Migration: 010_payment_atomicity.sql
-- Purpose: Atomic payment processing stored procedure
-- Description: Ensures all payment operations (purchase update,
--              ledger entry, wallet balance) succeed or fail together
-- =====================================================

-- Drop existing function if exists (for idempotent migrations)
DROP FUNCTION IF EXISTS process_payment_atomic(UUID, TEXT, UUID, UUID, INTEGER, INTEGER, INTEGER, TEXT);

-- Create atomic payment processing function
CREATE OR REPLACE FUNCTION process_payment_atomic(
  p_order_id UUID,
  p_transaction_id TEXT,
  p_wallet_id UUID,
  p_user_id UUID,
  p_total_dt INTEGER,
  p_dt_amount INTEGER,
  p_bonus_dt INTEGER,
  p_idempotency_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_existing_entry UUID;
  v_new_balance INTEGER;
  v_purchase_status TEXT;
BEGIN
  -- Check for existing ledger entry (idempotency check)
  SELECT id INTO v_existing_entry
  FROM ledger_entries
  WHERE idempotency_key = p_idempotency_key;

  IF v_existing_entry IS NOT NULL THEN
    RAISE EXCEPTION 'already_processed' USING ERRCODE = '23505';
  END IF;

  -- Verify purchase exists and is still pending
  SELECT status INTO v_purchase_status
  FROM dt_purchases
  WHERE id = p_order_id
  FOR UPDATE; -- Lock the row

  IF v_purchase_status IS NULL THEN
    RAISE EXCEPTION 'Purchase not found: %', p_order_id;
  END IF;

  IF v_purchase_status != 'pending' THEN
    RAISE EXCEPTION 'Purchase already processed with status: %', v_purchase_status;
  END IF;

  -- 1. Update purchase status
  UPDATE dt_purchases
  SET
    status = 'paid',
    paid_at = NOW(),
    payment_provider_transaction_id = p_transaction_id,
    updated_at = NOW()
  WHERE id = p_order_id;

  -- 2. Create wallet if not exists (upsert)
  INSERT INTO wallets (id, user_id, balance_dt, lifetime_purchased_dt, created_at, updated_at)
  VALUES (p_wallet_id, p_user_id, 0, 0, NOW(), NOW())
  ON CONFLICT (user_id) DO NOTHING;

  -- 3. Create ledger entry
  INSERT INTO ledger_entries (
    idempotency_key,
    to_wallet_id,
    amount_dt,
    entry_type,
    reference_type,
    reference_id,
    description,
    status,
    created_at
  )
  VALUES (
    p_idempotency_key,
    p_wallet_id,
    p_total_dt,
    'purchase',
    'purchase',
    p_order_id,
    format('DT 구매: %s DT + %s 보너스', p_dt_amount, p_bonus_dt),
    'completed',
    NOW()
  );

  -- 4. Update wallet balance (atomic increment)
  UPDATE wallets
  SET
    balance_dt = balance_dt + p_total_dt,
    lifetime_purchased_dt = lifetime_purchased_dt + p_total_dt,
    updated_at = NOW()
  WHERE user_id = p_user_id
  RETURNING balance_dt INTO v_new_balance;

  -- Return success with new balance
  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'credited_dt', p_total_dt,
    'new_balance', v_new_balance
  );
END;
$$;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION process_payment_atomic TO service_role;

-- Add comment for documentation
COMMENT ON FUNCTION process_payment_atomic IS
'Atomically processes a payment: updates purchase status, creates ledger entry, and updates wallet balance.
All operations succeed or fail together. Includes idempotency check via idempotency_key.';

-- =====================================================
-- Additional helper: Refund processing (atomic)
-- =====================================================

CREATE OR REPLACE FUNCTION process_refund_atomic(
  p_order_id UUID,
  p_refund_reason TEXT DEFAULT 'User requested refund'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_purchase RECORD;
  v_wallet_id UUID;
  v_new_balance INTEGER;
  v_idempotency_key TEXT;
BEGIN
  -- Get purchase details with lock
  SELECT * INTO v_purchase
  FROM dt_purchases
  WHERE id = p_order_id
  FOR UPDATE;

  IF v_purchase IS NULL THEN
    RAISE EXCEPTION 'Purchase not found: %', p_order_id;
  END IF;

  IF v_purchase.status != 'paid' THEN
    RAISE EXCEPTION 'Cannot refund purchase with status: %', v_purchase.status;
  END IF;

  -- Get wallet
  SELECT id INTO v_wallet_id
  FROM wallets
  WHERE user_id = v_purchase.user_id;

  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user: %', v_purchase.user_id;
  END IF;

  -- Idempotency key for refund
  v_idempotency_key := 'refund:' || p_order_id::TEXT;

  -- Check if already refunded
  IF EXISTS (SELECT 1 FROM ledger_entries WHERE idempotency_key = v_idempotency_key) THEN
    RAISE EXCEPTION 'already_processed' USING ERRCODE = '23505';
  END IF;

  -- 1. Update purchase status
  UPDATE dt_purchases
  SET
    status = 'refunded',
    updated_at = NOW()
  WHERE id = p_order_id;

  -- 2. Create refund ledger entry (negative amount)
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
  )
  VALUES (
    v_idempotency_key,
    v_wallet_id,
    -(v_purchase.dt_amount + v_purchase.bonus_dt),
    'refund',
    'purchase',
    p_order_id,
    format('DT 환불: %s (%s)', p_refund_reason, v_purchase.dt_amount + v_purchase.bonus_dt),
    'completed',
    NOW()
  );

  -- 3. Deduct from wallet balance
  UPDATE wallets
  SET
    balance_dt = balance_dt - (v_purchase.dt_amount + v_purchase.bonus_dt),
    updated_at = NOW()
  WHERE id = v_wallet_id
  RETURNING balance_dt INTO v_new_balance;

  -- Check for negative balance (shouldn't happen but safety check)
  IF v_new_balance < 0 THEN
    RAISE EXCEPTION 'Refund would result in negative balance';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'refunded_dt', v_purchase.dt_amount + v_purchase.bonus_dt,
    'new_balance', v_new_balance
  );
END;
$$;

GRANT EXECUTE ON FUNCTION process_refund_atomic TO service_role;

COMMENT ON FUNCTION process_refund_atomic IS
'Atomically processes a refund: updates purchase status, creates refund ledger entry, and deducts from wallet balance.';
