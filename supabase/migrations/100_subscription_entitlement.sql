-- ============================================
-- 100: Subscription Entitlement SSOT
-- ============================================
-- Links payment verification to subscription activation.
-- subscriptions table = Single Source of Truth for entitlement.
--
-- New columns:
--   payment_provider   TEXT   — 'tosspayments|web', 'apple|iap', 'google|iap'
--   payment_reference  TEXT   — payment key / receipt ID
--   activated_at       TIMESTAMPTZ — when subscription was activated after payment
--   entitlement_status TEXT   — 'pending', 'active', 'expired', 'revoked'
--
-- Default entitlement_status = 'active' for backward compatibility
-- (existing subscriptions remain active without re-verification).

-- ============================================
-- 1. Add entitlement columns to subscriptions
-- ============================================

ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS payment_provider TEXT,
  ADD COLUMN IF NOT EXISTS payment_reference TEXT,
  ADD COLUMN IF NOT EXISTS activated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS entitlement_status TEXT
    DEFAULT 'active'
    CHECK (entitlement_status IN ('pending', 'active', 'expired', 'revoked'));

-- Performance index for entitlement lookups
CREATE INDEX IF NOT EXISTS idx_subscriptions_entitlement
  ON public.subscriptions (user_id, channel_id, entitlement_status)
  WHERE entitlement_status = 'active';

-- Index for payment reference lookups (idempotency)
CREATE INDEX IF NOT EXISTS idx_subscriptions_payment_ref
  ON public.subscriptions (payment_provider, payment_reference)
  WHERE payment_reference IS NOT NULL;

-- ============================================
-- 2. activate_subscription RPC
-- ============================================
-- Called after payment verification (webhook or IAP verify).
-- UPSERT: creates or updates subscription, making it safe for duplicate calls.
-- SECURITY DEFINER: runs with elevated privileges, callable only from Edge Functions.

CREATE OR REPLACE FUNCTION public.activate_subscription(
  p_user_id UUID,
  p_channel_id UUID,
  p_payment_provider TEXT,
  p_payment_reference TEXT,
  p_tier TEXT DEFAULT 'STANDARD',
  p_duration_days INTEGER DEFAULT 30
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub_id UUID;
BEGIN
  -- Validate inputs
  IF p_user_id IS NULL OR p_channel_id IS NULL THEN
    RAISE EXCEPTION 'user_id and channel_id are required';
  END IF;

  IF p_payment_provider IS NULL OR p_payment_reference IS NULL THEN
    RAISE EXCEPTION 'payment_provider and payment_reference are required';
  END IF;

  IF p_tier NOT IN ('BASIC', 'STANDARD', 'VIP') THEN
    RAISE EXCEPTION 'Invalid tier: %', p_tier;
  END IF;

  IF p_duration_days < 1 OR p_duration_days > 365 THEN
    RAISE EXCEPTION 'duration_days must be between 1 and 365';
  END IF;

  -- UPSERT: Insert or update subscription
  INSERT INTO public.subscriptions (
    user_id,
    channel_id,
    tier,
    is_active,
    auto_renew,
    payment_provider,
    payment_reference,
    activated_at,
    entitlement_status,
    started_at,
    expires_at,
    created_at,
    updated_at
  ) VALUES (
    p_user_id,
    p_channel_id,
    p_tier,
    true,
    true,
    p_payment_provider,
    p_payment_reference,
    NOW(),
    'active',
    NOW(),
    NOW() + (p_duration_days || ' days')::INTERVAL,
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id, channel_id) DO UPDATE SET
    tier = EXCLUDED.tier,
    is_active = true,
    payment_provider = EXCLUDED.payment_provider,
    payment_reference = EXCLUDED.payment_reference,
    activated_at = NOW(),
    entitlement_status = 'active',
    expires_at = NOW() + (p_duration_days || ' days')::INTERVAL,
    updated_at = NOW()
  RETURNING id INTO v_sub_id;

  RETURN v_sub_id;
END;
$$;

-- ============================================
-- 3. deactivate_expired_subscriptions RPC
-- ============================================
-- Called by scheduled-dispatcher to expire subscriptions past their expires_at.

CREATE OR REPLACE FUNCTION public.deactivate_expired_subscriptions()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE public.subscriptions
  SET
    is_active = false,
    entitlement_status = 'expired',
    updated_at = NOW()
  WHERE
    is_active = true
    AND entitlement_status = 'active'
    AND expires_at IS NOT NULL
    AND expires_at < NOW();

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- ============================================
-- 4. revoke_subscription RPC
-- ============================================
-- Called on chargeback or manual revocation.

CREATE OR REPLACE FUNCTION public.revoke_subscription(
  p_user_id UUID,
  p_channel_id UUID,
  p_reason TEXT DEFAULT 'chargeback'
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.subscriptions
  SET
    is_active = false,
    entitlement_status = 'revoked',
    updated_at = NOW()
  WHERE
    user_id = p_user_id
    AND channel_id = p_channel_id
    AND is_active = true;

  RETURN FOUND;
END;
$$;

-- ============================================
-- 5. Restrict RPC access to service_role only
-- ============================================
-- These RPCs are called from Edge Functions (service_role),
-- not directly by authenticated users.

REVOKE EXECUTE ON FUNCTION public.activate_subscription(UUID, UUID, TEXT, TEXT, TEXT, INTEGER) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.activate_subscription(UUID, UUID, TEXT, TEXT, TEXT, INTEGER) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.activate_subscription(UUID, UUID, TEXT, TEXT, TEXT, INTEGER) FROM anon;

REVOKE EXECUTE ON FUNCTION public.deactivate_expired_subscriptions() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.deactivate_expired_subscriptions() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.deactivate_expired_subscriptions() FROM anon;

REVOKE EXECUTE ON FUNCTION public.revoke_subscription(UUID, UUID, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.revoke_subscription(UUID, UUID, TEXT) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.revoke_subscription(UUID, UUID, TEXT) FROM anon;
