-- =====================================================
-- Migration: 020_fix_atomic_refund_dt.sql
-- Purpose: Fix the process_refund_atomic function
-- Description: The original function tried to insert negative amount_dt
--              which violates the CHECK constraint (amount_dt > 0)
--
-- Fix: Use positive amount_dt and correct from_wallet_id/to_wallet_id
--      direction to represent the refund flow properly
-- =====================================================

-- Drop the buggy function
DROP FUNCTION IF EXISTS process_refund_atomic(UUID, TEXT);

-- Create the corrected function
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
  v_refund_dt INTEGER;
BEGIN
  -- 1. Get purchase details with lock
  SELECT * INTO v_purchase
  FROM dt_purchases
  WHERE id = p_order_id
  FOR UPDATE;

  IF v_purchase IS NULL THEN
    RAISE EXCEPTION 'Purchase not found: %', p_order_id;
  END IF;

  IF v_purchase.status NOT IN ('paid') THEN
    RAISE EXCEPTION 'Cannot refund purchase with status: %', v_purchase.status;
  END IF;

  -- 2. Check refund eligibility
  IF v_purchase.dt_used > 0 THEN
    RAISE EXCEPTION 'Cannot refund: DT already used (% DT)', v_purchase.dt_used;
  END IF;

  IF v_purchase.refund_eligible_until IS NOT NULL
     AND v_purchase.refund_eligible_until < NOW() THEN
    RAISE EXCEPTION 'Refund period has expired (eligible until: %)', v_purchase.refund_eligible_until;
  END IF;

  -- 3. Get user's wallet
  SELECT id INTO v_wallet_id
  FROM wallets
  WHERE user_id = v_purchase.user_id
  FOR UPDATE;

  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user: %', v_purchase.user_id;
  END IF;

  -- 4. Calculate refund amount
  v_refund_dt := v_purchase.dt_amount + v_purchase.bonus_dt;

  -- 5. Idempotency key for refund
  v_idempotency_key := 'refund:' || p_order_id::TEXT;

  -- 6. Check if already refunded (idempotency)
  IF EXISTS (SELECT 1 FROM ledger_entries WHERE idempotency_key = v_idempotency_key) THEN
    -- Return success for idempotent retry
    SELECT balance_dt INTO v_new_balance FROM wallets WHERE id = v_wallet_id;
    RETURN jsonb_build_object(
      'success', true,
      'already_processed', true,
      'order_id', p_order_id,
      'refunded_dt', v_refund_dt,
      'new_balance', v_new_balance
    );
  END IF;

  -- 7. Check if wallet has sufficient balance for refund deduction
  -- Note: Refund means we DEDUCT from user's wallet (they get KRW back, lose DT)
  IF (SELECT balance_dt FROM wallets WHERE id = v_wallet_id) < v_refund_dt THEN
    RAISE EXCEPTION 'Insufficient balance for refund. Current: %, Required: %',
      (SELECT balance_dt FROM wallets WHERE id = v_wallet_id), v_refund_dt;
  END IF;

  -- 8. Update purchase status
  UPDATE dt_purchases
  SET
    status = 'refunded',
    refunded_at = NOW(),
    refund_reason = p_refund_reason,
    refund_amount_krw = v_purchase.price_krw,
    updated_at = NOW()
  WHERE id = p_order_id;

  -- 9. Create refund ledger entry
  -- For a refund: DT flows FROM user wallet TO system (NULL)
  -- Amount is ALWAYS positive per CHECK constraint
  INSERT INTO ledger_entries (
    idempotency_key,
    from_wallet_id,
    to_wallet_id,
    amount_dt,
    entry_type,
    reference_type,
    reference_id,
    description,
    status,
    metadata,
    created_at
  )
  VALUES (
    v_idempotency_key,
    v_wallet_id,         -- FROM: user's wallet (DT is deducted)
    NULL,                -- TO: system (user gets KRW back externally)
    v_refund_dt,         -- POSITIVE amount (CHECK constraint satisfied)
    'refund',
    'purchase',
    p_order_id,
    format('DT 환불: %s DT (사유: %s)', v_refund_dt, p_refund_reason),
    'completed',
    jsonb_build_object(
      'original_dt_amount', v_purchase.dt_amount,
      'original_bonus_dt', v_purchase.bonus_dt,
      'refund_amount_krw', v_purchase.price_krw
    ),
    NOW()
  );

  -- 10. Deduct from wallet balance
  UPDATE wallets
  SET
    balance_dt = balance_dt - v_refund_dt,
    lifetime_refunded_dt = lifetime_refunded_dt + v_refund_dt,
    updated_at = NOW()
  WHERE id = v_wallet_id
  RETURNING balance_dt INTO v_new_balance;

  -- 11. Safety check (shouldn't happen due to earlier check, but defense in depth)
  IF v_new_balance < 0 THEN
    RAISE EXCEPTION 'Refund resulted in negative balance: %', v_new_balance;
  END IF;

  -- 12. Return success
  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'refunded_dt', v_refund_dt,
    'refund_amount_krw', v_purchase.price_krw,
    'new_balance', v_new_balance
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION process_refund_atomic TO service_role;

-- Add documentation
COMMENT ON FUNCTION process_refund_atomic IS
'Atomically processes a DT purchase refund:
1. Validates purchase status and refund eligibility
2. Checks wallet has sufficient balance
3. Updates purchase to refunded status
4. Creates ledger entry (positive amount, from user wallet to system)
5. Deducts DT from user wallet
6. Updates lifetime_refunded_dt stat

Includes idempotency check - safe to retry without duplicate processing.
Note: The actual KRW refund to payment method must be handled separately.';
