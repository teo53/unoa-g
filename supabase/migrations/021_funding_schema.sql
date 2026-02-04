-- ============================================
-- UNO A - Funding Campaign Schema
-- Version: 1.0.0
-- Description: Creator funding/crowdfunding system
-- ============================================

-- ============================================
-- 1. FUNDING CAMPAIGNS
-- ============================================
CREATE TABLE IF NOT EXISTS public.funding_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- URL-friendly identifier
  slug TEXT UNIQUE NOT NULL,

  -- Basic info
  title TEXT NOT NULL,
  subtitle TEXT,
  cover_image_url TEXT,
  category TEXT, -- 'music', 'video', 'merchandise', 'event', 'other'

  -- Status workflow: draft -> submitted -> approved/rejected -> active -> completed/cancelled
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft',       -- Creator is editing
    'submitted',   -- Awaiting admin review
    'approved',    -- Approved, waiting for start_at
    'rejected',    -- Rejected by admin
    'active',      -- Currently accepting pledges
    'completed',   -- Successfully ended
    'cancelled'    -- Cancelled by creator/admin
  )),

  -- Funding goals
  goal_amount_dt INT NOT NULL DEFAULT 0 CHECK (goal_amount_dt >= 0),
  current_amount_dt INT NOT NULL DEFAULT 0 CHECK (current_amount_dt >= 0),
  backer_count INT NOT NULL DEFAULT 0 CHECK (backer_count >= 0),

  -- Campaign period
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ,

  -- Content (stored as Markdown, edited via Tiptap block editor)
  description_md TEXT,
  description_html TEXT, -- Rendered HTML for display

  -- Admin review
  rejection_reason TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  submitted_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  -- Constraints
  CONSTRAINT valid_campaign_dates CHECK (
    start_at IS NULL OR end_at IS NULL OR start_at < end_at
  )
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_funding_campaigns_status ON funding_campaigns(status);
CREATE INDEX IF NOT EXISTS idx_funding_campaigns_creator ON funding_campaigns(creator_id);
CREATE INDEX IF NOT EXISTS idx_funding_campaigns_slug ON funding_campaigns(slug);
CREATE INDEX IF NOT EXISTS idx_funding_campaigns_active ON funding_campaigns(status, end_at)
  WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_funding_campaigns_browse ON funding_campaigns(status, created_at DESC)
  WHERE status IN ('active', 'completed');

-- ============================================
-- 2. FUNDING REWARD TIERS
-- ============================================
CREATE TABLE IF NOT EXISTS public.funding_reward_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES funding_campaigns(id) ON DELETE CASCADE,

  -- Tier info
  title TEXT NOT NULL,
  description TEXT,
  price_dt INT NOT NULL CHECK (price_dt > 0),

  -- Inventory (NULL = unlimited)
  total_quantity INT CHECK (total_quantity IS NULL OR total_quantity > 0),
  remaining_quantity INT CHECK (remaining_quantity IS NULL OR remaining_quantity >= 0),

  -- Display
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false, -- Highlighted tier

  -- Stats
  pledge_count INT DEFAULT 0 CHECK (pledge_count >= 0),

  -- Optional: Estimated delivery
  estimated_delivery_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Constraints
  CONSTRAINT valid_tier_quantity CHECK (
    remaining_quantity IS NULL OR
    total_quantity IS NULL OR
    remaining_quantity <= total_quantity
  )
);

CREATE INDEX IF NOT EXISTS idx_funding_tiers_campaign ON funding_reward_tiers(campaign_id, display_order);
CREATE INDEX IF NOT EXISTS idx_funding_tiers_active ON funding_reward_tiers(campaign_id, is_active)
  WHERE is_active = true;

-- ============================================
-- 3. FUNDING PLEDGES
-- ============================================
CREATE TABLE IF NOT EXISTS public.funding_pledges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES funding_campaigns(id),
  tier_id UUID REFERENCES funding_reward_tiers(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  -- Amount
  amount_dt INT NOT NULL CHECK (amount_dt > 0),
  extra_support_dt INT DEFAULT 0 CHECK (extra_support_dt >= 0),
  total_amount_dt INT GENERATED ALWAYS AS (amount_dt + extra_support_dt) STORED,

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending',    -- Created but not yet processed
    'paid',       -- Payment confirmed, DT deducted
    'cancelled',  -- Cancelled by user before completion
    'refunded'    -- Refunded after campaign end
  )),

  -- Ledger reference
  ledger_entry_id UUID REFERENCES ledger_entries(id),

  -- Idempotency
  idempotency_key TEXT UNIQUE,

  -- Optional info
  is_anonymous BOOLEAN DEFAULT false,
  support_message TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  paid_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_funding_pledges_campaign ON funding_pledges(campaign_id, status);
CREATE INDEX IF NOT EXISTS idx_funding_pledges_user ON funding_pledges(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_funding_pledges_tier ON funding_pledges(tier_id) WHERE tier_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_funding_pledges_idempotency ON funding_pledges(idempotency_key);

-- ============================================
-- 4. FUNDING FAQ ITEMS
-- ============================================
CREATE TABLE IF NOT EXISTS public.funding_faq_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES funding_campaigns(id) ON DELETE CASCADE,

  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  display_order INT DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_funding_faq_campaign ON funding_faq_items(campaign_id, display_order);

-- ============================================
-- 5. FUNDING UPDATES (Campaign news/announcements)
-- ============================================
CREATE TABLE IF NOT EXISTS public.funding_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES funding_campaigns(id) ON DELETE CASCADE,

  title TEXT NOT NULL,
  content_md TEXT NOT NULL,
  content_html TEXT, -- Rendered HTML

  -- Visibility
  is_public BOOLEAN DEFAULT true, -- false = backers only

  -- Stats
  view_count INT DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_funding_updates_campaign ON funding_updates(campaign_id, created_at DESC);

-- ============================================
-- 6. FUNDING PRELAUNCH SIGNUPS
-- ============================================
CREATE TABLE IF NOT EXISTS public.funding_prelaunch_signups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES funding_campaigns(id) ON DELETE CASCADE,

  -- Can be anonymous (just email) or authenticated user
  user_id UUID REFERENCES auth.users(id),
  email TEXT,

  -- Notification preferences
  notify_on_launch BOOLEAN DEFAULT true,

  created_at TIMESTAMPTZ DEFAULT now(),

  -- Prevent duplicates
  CONSTRAINT unique_prelaunch_signup UNIQUE NULLS NOT DISTINCT (campaign_id, user_id, email)
);

CREATE INDEX IF NOT EXISTS idx_prelaunch_campaign ON funding_prelaunch_signups(campaign_id);

-- ============================================
-- 7. UPDATE LEDGER_ENTRIES CONSTRAINT
-- Add 'funding' to allowed entry_type values
-- ============================================
ALTER TABLE ledger_entries DROP CONSTRAINT IF EXISTS ledger_entries_entry_type_check;
ALTER TABLE ledger_entries ADD CONSTRAINT ledger_entries_entry_type_check
  CHECK (entry_type IN (
    'purchase',        -- User buys DT
    'tip',             -- Fan tips creator
    'paid_reply',      -- Fan pays for reply token
    'private_card',    -- Fan buys private card
    'refund',          -- Refund to user
    'payout',          -- Creator withdraws (DT -> KRW)
    'adjustment',      -- Admin adjustment
    'bonus',           -- Promotional bonus
    'subscription',    -- Subscription payment
    'funding'          -- Funding pledge (NEW)
  ));

-- ============================================
-- 8. ENABLE RLS
-- ============================================
ALTER TABLE funding_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE funding_reward_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE funding_pledges ENABLE ROW LEVEL SECURITY;
ALTER TABLE funding_faq_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE funding_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE funding_prelaunch_signups ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 9. RLS POLICIES - FUNDING CAMPAIGNS
-- ============================================

-- Public can view active/completed campaigns
CREATE POLICY "Public can view active campaigns"
  ON funding_campaigns FOR SELECT
  USING (status IN ('active', 'completed'));

-- Authenticated users can also view approved campaigns (before start)
CREATE POLICY "Authenticated can view approved campaigns"
  ON funding_campaigns FOR SELECT
  TO authenticated
  USING (status = 'approved');

-- Creators can view/manage their own campaigns (any status)
CREATE POLICY "Creators can view own campaigns"
  ON funding_campaigns FOR SELECT
  TO authenticated
  USING (creator_id = auth.uid());

CREATE POLICY "Creators can insert own campaigns"
  ON funding_campaigns FOR INSERT
  TO authenticated
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Creators can update own draft/rejected campaigns"
  ON funding_campaigns FOR UPDATE
  TO authenticated
  USING (creator_id = auth.uid() AND status IN ('draft', 'rejected'))
  WITH CHECK (creator_id = auth.uid());

-- Admins can view/manage all campaigns
CREATE POLICY "Admins can view all campaigns"
  ON funding_campaigns FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Admins can update all campaigns"
  ON funding_campaigns FOR UPDATE
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- 10. RLS POLICIES - REWARD TIERS
-- ============================================

-- Public can view tiers of active/completed campaigns
CREATE POLICY "Public can view tiers of active campaigns"
  ON funding_reward_tiers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_reward_tiers.campaign_id
      AND status IN ('active', 'completed', 'approved')
    )
  );

-- Creators can manage tiers of their own campaigns
CREATE POLICY "Creators can view own campaign tiers"
  ON funding_reward_tiers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_reward_tiers.campaign_id
      AND creator_id = auth.uid()
    )
  );

CREATE POLICY "Creators can insert tiers for own campaigns"
  ON funding_reward_tiers FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_reward_tiers.campaign_id
      AND creator_id = auth.uid()
      AND status IN ('draft', 'rejected')
    )
  );

CREATE POLICY "Creators can update tiers of own draft campaigns"
  ON funding_reward_tiers FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_reward_tiers.campaign_id
      AND creator_id = auth.uid()
      AND status IN ('draft', 'rejected')
    )
  );

CREATE POLICY "Creators can delete tiers of own draft campaigns"
  ON funding_reward_tiers FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_reward_tiers.campaign_id
      AND creator_id = auth.uid()
      AND status IN ('draft', 'rejected')
    )
  );

-- Admins can manage all tiers
CREATE POLICY "Admins can manage all tiers"
  ON funding_reward_tiers FOR ALL
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- 11. RLS POLICIES - PLEDGES
-- ============================================

-- Users can view their own pledges
CREATE POLICY "Users can view own pledges"
  ON funding_pledges FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can insert pledges for active campaigns
CREATE POLICY "Users can create pledges"
  ON funding_pledges FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_pledges.campaign_id
      AND status = 'active'
      AND (end_at IS NULL OR end_at > now())
    )
  );

-- Creators can view pledges for their campaigns (for analytics)
CREATE POLICY "Creators can view campaign pledges"
  ON funding_pledges FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_pledges.campaign_id
      AND creator_id = auth.uid()
    )
  );

-- Admins can view all pledges
CREATE POLICY "Admins can view all pledges"
  ON funding_pledges FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- 12. RLS POLICIES - FAQ ITEMS
-- ============================================

-- Public can view FAQs of active campaigns
CREATE POLICY "Public can view FAQs"
  ON funding_faq_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_faq_items.campaign_id
      AND status IN ('active', 'completed', 'approved')
    )
  );

-- Creators can manage FAQs of their own campaigns
CREATE POLICY "Creators can view own FAQs"
  ON funding_faq_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_faq_items.campaign_id
      AND creator_id = auth.uid()
    )
  );

CREATE POLICY "Creators can manage own FAQs"
  ON funding_faq_items FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_faq_items.campaign_id
      AND creator_id = auth.uid()
    )
  );

-- Admins can manage all FAQs
CREATE POLICY "Admins can manage all FAQs"
  ON funding_faq_items FOR ALL
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- 13. RLS POLICIES - UPDATES
-- ============================================

-- Public can view public updates of active campaigns
CREATE POLICY "Public can view public updates"
  ON funding_updates FOR SELECT
  USING (
    is_public = true
    AND EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_updates.campaign_id
      AND status IN ('active', 'completed')
    )
  );

-- Backers can view all updates (including private)
CREATE POLICY "Backers can view all updates"
  ON funding_updates FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM funding_pledges
      WHERE campaign_id = funding_updates.campaign_id
      AND user_id = auth.uid()
      AND status = 'paid'
    )
  );

-- Creators can manage updates of their own campaigns
CREATE POLICY "Creators can manage own updates"
  ON funding_updates FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_updates.campaign_id
      AND creator_id = auth.uid()
    )
  );

-- Admins can manage all updates
CREATE POLICY "Admins can manage all updates"
  ON funding_updates FOR ALL
  TO authenticated
  USING (public.is_admin());

-- ============================================
-- 14. RLS POLICIES - PRELAUNCH SIGNUPS
-- ============================================

-- Anyone can sign up for prelaunch
CREATE POLICY "Anyone can create prelaunch signup"
  ON funding_prelaunch_signups FOR INSERT
  WITH CHECK (
    -- Must provide either user_id (authenticated) or email (anonymous)
    (auth.uid() IS NOT NULL AND user_id = auth.uid())
    OR (auth.uid() IS NULL AND email IS NOT NULL)
  );

-- Users can view their own signups
CREATE POLICY "Users can view own signups"
  ON funding_prelaunch_signups FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Creators can view signups for their campaigns
CREATE POLICY "Creators can view campaign signups"
  ON funding_prelaunch_signups FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM funding_campaigns
      WHERE id = funding_prelaunch_signups.campaign_id
      AND creator_id = auth.uid()
    )
  );

-- ============================================
-- 15. HELPER FUNCTIONS
-- ============================================

-- Generate unique slug from title
CREATE OR REPLACE FUNCTION public.generate_campaign_slug(p_title TEXT, p_creator_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_base_slug TEXT;
  v_slug TEXT;
  v_counter INT := 0;
BEGIN
  -- Create base slug from title (Korean-friendly)
  v_base_slug := lower(regexp_replace(p_title, '[^a-zA-Z0-9가-힣]+', '-', 'g'));
  v_base_slug := trim(both '-' from v_base_slug);

  -- Limit length
  IF length(v_base_slug) > 50 THEN
    v_base_slug := left(v_base_slug, 50);
  END IF;

  -- Add random suffix for uniqueness
  v_slug := v_base_slug || '-' || substring(gen_random_uuid()::text, 1, 8);

  -- Ensure uniqueness
  WHILE EXISTS (SELECT 1 FROM funding_campaigns WHERE slug = v_slug) LOOP
    v_counter := v_counter + 1;
    v_slug := v_base_slug || '-' || substring(gen_random_uuid()::text, 1, 8);
    IF v_counter > 10 THEN
      RAISE EXCEPTION 'Could not generate unique slug';
    END IF;
  END LOOP;

  RETURN v_slug;
END;
$$ LANGUAGE plpgsql;

-- Calculate campaign funding percentage
CREATE OR REPLACE FUNCTION public.get_funding_percentage(p_current INT, p_goal INT)
RETURNS INT AS $$
BEGIN
  IF p_goal <= 0 THEN
    RETURN 0;
  END IF;
  RETURN FLOOR((p_current::NUMERIC / p_goal::NUMERIC) * 100);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Check if campaign is fundable
CREATE OR REPLACE FUNCTION public.is_campaign_fundable(p_campaign_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM funding_campaigns
    WHERE id = p_campaign_id
    AND status = 'active'
    AND (end_at IS NULL OR end_at > now())
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- Check if tier is available
CREATE OR REPLACE FUNCTION public.is_tier_available(p_tier_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM funding_reward_tiers
    WHERE id = p_tier_id
    AND is_active = true
    AND (remaining_quantity IS NULL OR remaining_quantity > 0)
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- 16. TRIGGERS
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_funding_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_funding_campaigns_updated_at
  BEFORE UPDATE ON funding_campaigns
  FOR EACH ROW EXECUTE FUNCTION update_funding_updated_at();

CREATE TRIGGER trigger_funding_tiers_updated_at
  BEFORE UPDATE ON funding_reward_tiers
  FOR EACH ROW EXECUTE FUNCTION update_funding_updated_at();

CREATE TRIGGER trigger_funding_faq_updated_at
  BEFORE UPDATE ON funding_faq_items
  FOR EACH ROW EXECUTE FUNCTION update_funding_updated_at();

CREATE TRIGGER trigger_funding_updates_updated_at
  BEFORE UPDATE ON funding_updates
  FOR EACH ROW EXECUTE FUNCTION update_funding_updated_at();

-- Auto-generate slug on campaign insert
CREATE OR REPLACE FUNCTION public.auto_generate_campaign_slug()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := public.generate_campaign_slug(NEW.title, NEW.creator_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_campaign_slug
  BEFORE INSERT ON funding_campaigns
  FOR EACH ROW EXECUTE FUNCTION auto_generate_campaign_slug();

-- ============================================
-- 17. STORAGE BUCKETS (via SQL - needs Supabase Dashboard too)
-- ============================================
-- Note: Storage bucket creation is typically done via Supabase Dashboard
-- or using the Storage API. The following is documentation:
--
-- Bucket: campaign-images
-- - Public: true (for cover images, story images)
-- - File size limit: 10MB
-- - Allowed MIME types: image/jpeg, image/png, image/webp, image/gif
--
-- Bucket: campaign-files
-- - Public: false (requires auth)
-- - File size limit: 50MB
-- - Allowed MIME types: application/pdf, video/*

-- ============================================
-- 18. GRANT PERMISSIONS
-- ============================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

GRANT SELECT ON funding_campaigns TO anon;
GRANT SELECT ON funding_reward_tiers TO anon;
GRANT SELECT ON funding_faq_items TO anon;
GRANT SELECT ON funding_updates TO anon;
GRANT INSERT ON funding_prelaunch_signups TO anon;

GRANT ALL ON funding_campaigns TO authenticated;
GRANT ALL ON funding_reward_tiers TO authenticated;
GRANT ALL ON funding_pledges TO authenticated;
GRANT ALL ON funding_faq_items TO authenticated;
GRANT ALL ON funding_updates TO authenticated;
GRANT ALL ON funding_prelaunch_signups TO authenticated;

GRANT EXECUTE ON FUNCTION public.generate_campaign_slug TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_funding_percentage TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_funding_percentage TO anon;
GRANT EXECUTE ON FUNCTION public.is_campaign_fundable TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_tier_available TO authenticated;

-- ============================================
-- 19. ATOMIC FUNDING PLEDGE FUNCTION
-- Used by funding-pledge Edge Function
-- ============================================
CREATE OR REPLACE FUNCTION public.process_funding_pledge(
  p_campaign_id UUID,
  p_tier_id UUID,
  p_user_id UUID,
  p_wallet_id UUID,
  p_amount_dt INT,
  p_extra_support_dt INT DEFAULT 0,
  p_idempotency_key TEXT DEFAULT NULL,
  p_is_anonymous BOOLEAN DEFAULT false,
  p_support_message TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_amount INT;
  v_wallet wallets;
  v_campaign funding_campaigns;
  v_tier funding_reward_tiers;
  v_pledge funding_pledges;
  v_ledger ledger_entries;
  v_new_balance INT;
  v_ledger_idempotency TEXT;
BEGIN
  -- Calculate total
  v_total_amount := p_amount_dt + COALESCE(p_extra_support_dt, 0);

  -- Check idempotency
  IF p_idempotency_key IS NOT NULL THEN
    SELECT * INTO v_pledge FROM funding_pledges WHERE idempotency_key = p_idempotency_key;
    IF v_pledge.id IS NOT NULL THEN
      -- Already processed, return existing
      SELECT balance_dt INTO v_new_balance FROM wallets WHERE id = p_wallet_id;
      RETURN jsonb_build_object(
        'pledge_id', v_pledge.id,
        'new_balance', v_new_balance,
        'already_processed', true
      );
    END IF;
  END IF;

  -- Lock wallet row for update
  SELECT * INTO v_wallet FROM wallets WHERE id = p_wallet_id FOR UPDATE;
  IF v_wallet.id IS NULL THEN
    RAISE EXCEPTION 'wallet_not_found';
  END IF;

  -- Check balance
  IF v_wallet.balance_dt < v_total_amount THEN
    RAISE EXCEPTION 'insufficient_balance';
  END IF;

  -- Lock campaign row for update
  SELECT * INTO v_campaign FROM funding_campaigns WHERE id = p_campaign_id FOR UPDATE;
  IF v_campaign.id IS NULL THEN
    RAISE EXCEPTION 'campaign_not_found';
  END IF;

  -- Check campaign status
  IF v_campaign.status != 'active' THEN
    RAISE EXCEPTION 'campaign_not_active';
  END IF;

  -- Check campaign end date
  IF v_campaign.end_at IS NOT NULL AND v_campaign.end_at < now() THEN
    RAISE EXCEPTION 'campaign_ended';
  END IF;

  -- Handle tier if provided
  IF p_tier_id IS NOT NULL THEN
    SELECT * INTO v_tier FROM funding_reward_tiers
    WHERE id = p_tier_id AND campaign_id = p_campaign_id FOR UPDATE;

    IF v_tier.id IS NULL THEN
      RAISE EXCEPTION 'tier_not_found';
    END IF;

    IF NOT v_tier.is_active THEN
      RAISE EXCEPTION 'tier_not_active';
    END IF;

    IF v_tier.remaining_quantity IS NOT NULL AND v_tier.remaining_quantity <= 0 THEN
      RAISE EXCEPTION 'tier_sold_out';
    END IF;

    -- Update tier stats
    UPDATE funding_reward_tiers SET
      remaining_quantity = CASE
        WHEN remaining_quantity IS NOT NULL THEN remaining_quantity - 1
        ELSE NULL
      END,
      pledge_count = pledge_count + 1,
      updated_at = now()
    WHERE id = p_tier_id;
  END IF;

  -- Generate ledger idempotency key
  v_ledger_idempotency := 'funding:' || COALESCE(p_idempotency_key, gen_random_uuid()::text);

  -- Create ledger entry
  INSERT INTO ledger_entries (
    idempotency_key,
    from_wallet_id,
    to_wallet_id,
    amount_dt,
    entry_type,
    reference_type,
    reference_id,
    description,
    metadata,
    status
  ) VALUES (
    v_ledger_idempotency,
    p_wallet_id,
    NULL, -- Platform receives (no specific wallet)
    v_total_amount,
    'funding',
    'funding_pledge',
    NULL, -- Will update with pledge ID
    'Funding pledge for campaign: ' || v_campaign.title,
    jsonb_build_object(
      'campaign_id', p_campaign_id,
      'tier_id', p_tier_id,
      'amount_dt', p_amount_dt,
      'extra_support_dt', p_extra_support_dt
    ),
    'completed'
  ) RETURNING * INTO v_ledger;

  -- Deduct from wallet
  UPDATE wallets SET
    balance_dt = balance_dt - v_total_amount,
    lifetime_spent_dt = lifetime_spent_dt + v_total_amount,
    updated_at = now()
  WHERE id = p_wallet_id
  RETURNING balance_dt INTO v_new_balance;

  -- Create pledge record
  INSERT INTO funding_pledges (
    campaign_id,
    tier_id,
    user_id,
    amount_dt,
    extra_support_dt,
    status,
    ledger_entry_id,
    idempotency_key,
    is_anonymous,
    support_message,
    paid_at
  ) VALUES (
    p_campaign_id,
    p_tier_id,
    p_user_id,
    p_amount_dt,
    COALESCE(p_extra_support_dt, 0),
    'paid',
    v_ledger.id,
    p_idempotency_key,
    p_is_anonymous,
    p_support_message,
    now()
  ) RETURNING * INTO v_pledge;

  -- Update ledger reference
  UPDATE ledger_entries SET
    reference_id = v_pledge.id
  WHERE id = v_ledger.id;

  -- Update campaign stats
  UPDATE funding_campaigns SET
    current_amount_dt = current_amount_dt + v_total_amount,
    backer_count = backer_count + 1,
    updated_at = now()
  WHERE id = p_campaign_id;

  -- Return result
  RETURN jsonb_build_object(
    'pledge_id', v_pledge.id,
    'new_balance', v_new_balance,
    'total_amount', v_total_amount,
    'already_processed', false
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.process_funding_pledge TO service_role;
