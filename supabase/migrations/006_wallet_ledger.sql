-- ============================================
-- UNO A - Wallet & Ledger Schema
-- Version: 1.1.0
-- ============================================

-- ============================================
-- 1. WALLETS (per user)
-- ============================================
CREATE TABLE IF NOT EXISTS public.wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,

  -- Current balance (cached from ledger)
  balance_dt INT NOT NULL DEFAULT 0 CHECK (balance_dt >= 0),

  -- Lifetime stats
  lifetime_purchased_dt BIGINT DEFAULT 0,
  lifetime_spent_dt BIGINT DEFAULT 0,
  lifetime_earned_dt BIGINT DEFAULT 0, -- For creators
  lifetime_refunded_dt BIGINT DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wallets_user ON wallets(user_id);

-- ============================================
-- 2. LEDGER ENTRIES (double-entry with idempotency)
-- ============================================
CREATE TABLE IF NOT EXISTS public.ledger_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Idempotency key prevents duplicate transactions
  idempotency_key TEXT UNIQUE NOT NULL,

  -- Transaction parties (NULL = system)
  from_wallet_id UUID REFERENCES wallets(id),
  to_wallet_id UUID REFERENCES wallets(id),

  -- Amount (always positive)
  amount_dt INT NOT NULL CHECK (amount_dt > 0),

  -- Transaction type
  entry_type TEXT NOT NULL CHECK (entry_type IN (
    'purchase',        -- User buys DT
    'tip',             -- Fan tips creator
    'paid_reply',      -- Fan pays for reply token
    'private_card',    -- Fan buys private card
    'refund',          -- Refund to user
    'payout',          -- Creator withdraws (DT -> KRW)
    'adjustment',      -- Admin adjustment
    'bonus',           -- Promotional bonus
    'subscription'     -- Subscription payment
  )),

  -- Reference to related entity
  reference_type TEXT, -- 'purchase', 'donation', 'payout', 'message', etc.
  reference_id UUID,

  -- Description and metadata
  description TEXT,
  metadata JSONB DEFAULT '{}',

  -- Status
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  processed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ledger_from_wallet ON ledger_entries(from_wallet_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ledger_to_wallet ON ledger_entries(to_wallet_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ledger_idempotency ON ledger_entries(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_ledger_type ON ledger_entries(entry_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ledger_status ON ledger_entries(status) WHERE status != 'completed';
CREATE INDEX IF NOT EXISTS idx_ledger_reference ON ledger_entries(reference_type, reference_id);

-- ============================================
-- 3. DT PURCHASE ORDERS
-- ============================================
CREATE TABLE IF NOT EXISTS public.dt_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  -- Package info
  package_id TEXT NOT NULL,
  dt_amount INT NOT NULL,
  bonus_dt INT DEFAULT 0,
  price_krw INT NOT NULL,

  -- Payment info
  payment_method TEXT, -- 'card', 'kakao', 'naver', 'toss', 'apple', 'google'
  payment_provider TEXT, -- 'tosspayments', 'iamport', 'apple', 'google'
  payment_provider_order_id TEXT,
  payment_provider_transaction_id TEXT,

  -- Receipt info
  receipt_url TEXT,
  receipt_type TEXT, -- 'income', 'cash'

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending',     -- Created, awaiting payment
    'paid',        -- Payment confirmed, DT credited
    'cancelled',   -- Cancelled before payment
    'refunded',    -- Fully refunded
    'partial_refund', -- Partially refunded
    'failed'       -- Payment failed
  )),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  paid_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ,

  -- Refund tracking
  dt_used INT DEFAULT 0, -- DT used from this purchase
  refund_eligible_until TIMESTAMPTZ, -- 7 days from paid_at
  refund_reason TEXT,
  refund_amount_krw INT -- Amount refunded (may be partial)
);

CREATE INDEX IF NOT EXISTS idx_purchases_user ON dt_purchases(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_purchases_status ON dt_purchases(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_purchases_refund ON dt_purchases(refund_eligible_until)
  WHERE status = 'paid' AND dt_used = 0;
CREATE INDEX IF NOT EXISTS idx_purchases_provider ON dt_purchases(payment_provider, payment_provider_order_id);

-- ============================================
-- 4. DT DONATIONS (Tips/땡큐스티커)
-- ============================================
CREATE TABLE IF NOT EXISTS public.dt_donations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Parties
  from_user_id UUID NOT NULL REFERENCES auth.users(id),
  to_channel_id UUID NOT NULL REFERENCES channels(id),
  to_creator_id UUID NOT NULL REFERENCES auth.users(id),

  -- Amount
  amount_dt INT NOT NULL CHECK (amount_dt > 0),

  -- Associated message (if any)
  message_id UUID REFERENCES messages(id),

  -- Anonymous donation
  is_anonymous BOOLEAN DEFAULT false,

  -- Revenue split (calculated at time of donation)
  platform_fee_rate NUMERIC DEFAULT 0.20, -- 20% platform fee
  creator_share_dt INT NOT NULL,
  platform_fee_dt INT NOT NULL,

  -- Ledger reference
  ledger_entry_id UUID REFERENCES ledger_entries(id),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_donations_from ON dt_donations(from_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_donations_to_channel ON dt_donations(to_channel_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_donations_to_creator ON dt_donations(to_creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_donations_message ON dt_donations(message_id);

-- ============================================
-- 5. PRIVATE CARDS (Paid exclusive content)
-- ============================================
CREATE TABLE IF NOT EXISTS public.private_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id),
  creator_id UUID NOT NULL REFERENCES auth.users(id),

  -- Content
  title TEXT NOT NULL,
  description TEXT,
  media_type TEXT CHECK (media_type IN ('image', 'video', 'audio')),
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  media_duration_seconds INT, -- For video/audio

  -- Pricing
  price_dt INT NOT NULL CHECK (price_dt > 0),

  -- Availability
  is_active BOOLEAN DEFAULT true,
  available_from TIMESTAMPTZ DEFAULT now(),
  available_until TIMESTAMPTZ,
  max_purchases INT, -- NULL = unlimited

  -- Stats
  purchase_count INT DEFAULT 0,
  total_revenue_dt BIGINT DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_private_cards_channel ON private_cards(channel_id, is_active, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_private_cards_creator ON private_cards(creator_id);

-- ============================================
-- 6. PRIVATE CARD PURCHASES
-- ============================================
CREATE TABLE IF NOT EXISTS public.private_card_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES private_cards(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  -- Price at time of purchase
  price_paid_dt INT NOT NULL,

  -- Ledger reference
  ledger_entry_id UUID REFERENCES ledger_entries(id),

  -- View tracking
  first_viewed_at TIMESTAMPTZ,
  view_count INT DEFAULT 0,
  last_viewed_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_card_user_purchase UNIQUE(card_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_card_purchases_user ON private_card_purchases(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_card_purchases_card ON private_card_purchases(card_id);

-- ============================================
-- 7. DT PACKAGES (Configurable)
-- ============================================
CREATE TABLE IF NOT EXISTS public.dt_packages (
  id TEXT PRIMARY KEY, -- e.g., 'dt_100', 'dt_500'
  name TEXT NOT NULL,
  description TEXT,
  dt_amount INT NOT NULL,
  bonus_dt INT DEFAULT 0,
  price_krw INT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  display_order INT DEFAULT 0,
  badge_text TEXT, -- e.g., 'BEST', '인기'
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Default packages (Fancim "샷" style: 1 DT = 100 KRW)
INSERT INTO dt_packages (id, name, description, dt_amount, bonus_dt, price_krw, display_order, badge_text) VALUES
  ('dt_10', '10 DT', '소소한 응원', 10, 0, 1000, 1, NULL),
  ('dt_50', '50 DT', '작은 선물', 50, 0, 5000, 2, NULL),
  ('dt_100', '100 DT', '기본 패키지', 100, 5, 10000, 3, NULL),
  ('dt_500', '500 DT', '인기 패키지', 500, 50, 50000, 4, '인기'),
  ('dt_1000', '1,000 DT', '프리미엄 패키지', 1000, 150, 100000, 5, 'BEST'),
  ('dt_5000', '5,000 DT', 'VIP 패키지', 5000, 1000, 500000, 6, 'VIP')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  dt_amount = EXCLUDED.dt_amount,
  bonus_dt = EXCLUDED.bonus_dt,
  price_krw = EXCLUDED.price_krw,
  display_order = EXCLUDED.display_order,
  badge_text = EXCLUDED.badge_text;

-- ============================================
-- 8. RLS POLICIES
-- ============================================
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE dt_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE dt_donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE private_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE private_card_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE dt_packages ENABLE ROW LEVEL SECURITY;

-- Wallets
CREATE POLICY "Users can view own wallet"
  ON wallets FOR SELECT
  USING (user_id = auth.uid());

-- Ledger entries
CREATE POLICY "Users can view own ledger entries"
  ON ledger_entries FOR SELECT
  USING (
    from_wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid())
    OR to_wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid())
  );

-- DT Purchases
CREATE POLICY "Users can view own purchases"
  ON dt_purchases FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create own purchases"
  ON dt_purchases FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- DT Donations
CREATE POLICY "Users can view own donations (sent)"
  ON dt_donations FOR SELECT
  USING (from_user_id = auth.uid());

CREATE POLICY "Creators can view received donations"
  ON dt_donations FOR SELECT
  USING (to_creator_id = auth.uid());

CREATE POLICY "Users can create donations"
  ON dt_donations FOR INSERT
  WITH CHECK (from_user_id = auth.uid());

-- Private Cards
CREATE POLICY "Anyone can view active cards"
  ON private_cards FOR SELECT
  USING (is_active = true AND auth.uid() IS NOT NULL);

CREATE POLICY "Creators can manage own cards"
  ON private_cards FOR ALL
  USING (creator_id = auth.uid());

-- Private Card Purchases
CREATE POLICY "Users can view own card purchases"
  ON private_card_purchases FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create card purchases"
  ON private_card_purchases FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own card purchases (view tracking)"
  ON private_card_purchases FOR UPDATE
  USING (user_id = auth.uid());

-- DT Packages (public read)
CREATE POLICY "Anyone can view active packages"
  ON dt_packages FOR SELECT
  USING (is_active = true);

-- ============================================
-- 9. HELPER FUNCTIONS
-- ============================================

-- Get wallet balance
CREATE OR REPLACE FUNCTION public.get_wallet_balance(p_user_id UUID)
RETURNS INT AS $$
  SELECT COALESCE(balance_dt, 0) FROM wallets WHERE user_id = p_user_id;
$$ LANGUAGE sql STABLE;

-- Check if user can afford amount
CREATE OR REPLACE FUNCTION public.can_afford(p_user_id UUID, p_amount INT)
RETURNS BOOLEAN AS $$
  SELECT COALESCE(balance_dt, 0) >= p_amount FROM wallets WHERE user_id = p_user_id;
$$ LANGUAGE sql STABLE;

-- Process wallet transaction (used by Edge Functions)
CREATE OR REPLACE FUNCTION public.process_wallet_transaction(
  p_idempotency_key TEXT,
  p_from_user_id UUID,
  p_to_user_id UUID,
  p_amount_dt INT,
  p_entry_type TEXT,
  p_reference_type TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS ledger_entries AS $$
DECLARE
  v_from_wallet wallets;
  v_to_wallet wallets;
  v_entry ledger_entries;
BEGIN
  -- Check idempotency
  SELECT * INTO v_entry FROM ledger_entries WHERE idempotency_key = p_idempotency_key;
  IF v_entry.id IS NOT NULL THEN
    RETURN v_entry; -- Already processed
  END IF;

  -- Get wallets
  IF p_from_user_id IS NOT NULL THEN
    SELECT * INTO v_from_wallet FROM wallets WHERE user_id = p_from_user_id FOR UPDATE;
    IF v_from_wallet.id IS NULL THEN
      RAISE EXCEPTION 'Source wallet not found';
    END IF;
    IF v_from_wallet.balance_dt < p_amount_dt THEN
      RAISE EXCEPTION 'Insufficient balance';
    END IF;
  END IF;

  IF p_to_user_id IS NOT NULL THEN
    SELECT * INTO v_to_wallet FROM wallets WHERE user_id = p_to_user_id FOR UPDATE;
    IF v_to_wallet.id IS NULL THEN
      RAISE EXCEPTION 'Destination wallet not found';
    END IF;
  END IF;

  -- Create ledger entry
  INSERT INTO ledger_entries (
    idempotency_key, from_wallet_id, to_wallet_id, amount_dt,
    entry_type, reference_type, reference_id, description, metadata
  ) VALUES (
    p_idempotency_key, v_from_wallet.id, v_to_wallet.id, p_amount_dt,
    p_entry_type, p_reference_type, p_reference_id, p_description, p_metadata
  ) RETURNING * INTO v_entry;

  -- Update balances
  IF v_from_wallet.id IS NOT NULL THEN
    UPDATE wallets SET
      balance_dt = balance_dt - p_amount_dt,
      lifetime_spent_dt = lifetime_spent_dt + p_amount_dt,
      updated_at = now()
    WHERE id = v_from_wallet.id;
  END IF;

  IF v_to_wallet.id IS NOT NULL THEN
    UPDATE wallets SET
      balance_dt = balance_dt + p_amount_dt,
      lifetime_earned_dt = CASE
        WHEN p_entry_type IN ('tip', 'paid_reply', 'private_card') THEN lifetime_earned_dt + p_amount_dt
        ELSE lifetime_earned_dt
      END,
      lifetime_purchased_dt = CASE
        WHEN p_entry_type = 'purchase' THEN lifetime_purchased_dt + p_amount_dt
        ELSE lifetime_purchased_dt
      END,
      updated_at = now()
    WHERE id = v_to_wallet.id;
  END IF;

  RETURN v_entry;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Calculate platform fee and creator share
CREATE OR REPLACE FUNCTION public.calculate_revenue_split(p_amount_dt INT, p_platform_fee_rate NUMERIC DEFAULT 0.20)
RETURNS TABLE (creator_share INT, platform_fee INT) AS $$
BEGIN
  platform_fee := FLOOR(p_amount_dt * p_platform_fee_rate);
  creator_share := p_amount_dt - platform_fee;
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 10. ADD DEFERRED FK: messages.donation_id -> dt_donations
-- (messages table created in 001 before dt_donations existed)
-- ============================================
ALTER TABLE public.messages
  ADD CONSTRAINT fk_messages_donation
  FOREIGN KEY (donation_id) REFERENCES dt_donations(id) ON DELETE SET NULL;
