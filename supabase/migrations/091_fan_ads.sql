-- ============================================
-- 060: Fan Advertising System
-- ============================================
-- Fans can purchase ad slots (KRW) to promote their favorite artists
-- within the app. Ads go through admin review before activation.
-- Integrates with existing ops_banners for unified banner delivery.

BEGIN;

-- Ad packages (admin-configurable pricing)
CREATE TABLE IF NOT EXISTS public.fan_ad_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  placement TEXT NOT NULL,      -- 'home_top', 'discover_top', 'chat_list', 'funding_top'
  duration_days INT NOT NULL,
  price_krw INT NOT NULL,
  max_impressions INT,          -- NULL = unlimited
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Fan ad orders
CREATE TABLE IF NOT EXISTS public.fan_ads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fan_user_id UUID NOT NULL REFERENCES auth.users(id),
  package_id UUID NOT NULL REFERENCES public.fan_ad_packages(id),
  target_artist_id TEXT NOT NULL,

  -- Ad content
  headline TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  link_type TEXT DEFAULT 'profile',  -- 'profile', 'funding', 'event'
  link_target TEXT,

  -- Payment
  payment_amount_krw INT NOT NULL,
  payment_id TEXT,                   -- PortOne payment ID
  payment_status TEXT DEFAULT 'pending', -- pending, paid, refunded

  -- Status
  status TEXT DEFAULT 'pending_review', -- pending_review, approved, rejected, active, completed, cancelled
  reject_reason TEXT,

  -- Schedule
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,

  -- Stats
  impressions INT DEFAULT 0,
  clicks INT DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES auth.users(id)
);

-- Extend ops_banners with source tracking
ALTER TABLE public.ops_banners
  ADD COLUMN IF NOT EXISTS source_type TEXT DEFAULT 'ops',  -- 'ops', 'creator_promo', 'fan_ad'
  ADD COLUMN IF NOT EXISTS fan_ad_id UUID REFERENCES public.fan_ads(id);

-- Insert default ad packages
INSERT INTO public.fan_ad_packages (name, placement, duration_days, price_krw) VALUES
  ('홈 배너 1일', 'home_top', 1, 5000),
  ('홈 배너 3일', 'home_top', 3, 12000),
  ('탐색 상단 1일', 'discover_top', 1, 3000),
  ('탐색 상단 3일', 'discover_top', 3, 8000),
  ('채팅 리스트 1일', 'chat_list', 1, 4000),
  ('채팅 리스트 3일', 'chat_list', 3, 10000),
  ('펀딩 상단 1일', 'funding_top', 1, 3000),
  ('펀딩 상단 7일', 'funding_top', 7, 15000)
ON CONFLICT DO NOTHING;

-- RLS
ALTER TABLE public.fan_ad_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fan_ads ENABLE ROW LEVEL SECURITY;

-- Anyone can read active packages
CREATE POLICY "fan_ad_packages_public_read" ON public.fan_ad_packages
  FOR SELECT TO authenticated USING (is_active = true);

-- Only ops staff can manage packages
CREATE POLICY "fan_ad_packages_ops_write" ON public.fan_ad_packages
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.ops_staff WHERE user_id = auth.uid() AND role IN ('admin', 'operator'))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.ops_staff WHERE user_id = auth.uid() AND role IN ('admin', 'operator'))
  );

-- Fans can read/create their own ads
CREATE POLICY "fan_ads_own_read" ON public.fan_ads
  FOR SELECT TO authenticated USING (fan_user_id = auth.uid());

CREATE POLICY "fan_ads_own_insert" ON public.fan_ads
  FOR INSERT TO authenticated WITH CHECK (fan_user_id = auth.uid());

CREATE POLICY "fan_ads_own_update" ON public.fan_ads
  FOR UPDATE TO authenticated
  USING (fan_user_id = auth.uid() AND status IN ('pending_review', 'rejected'))
  WITH CHECK (fan_user_id = auth.uid());

-- Ops staff can manage all ads
CREATE POLICY "fan_ads_ops_all" ON public.fan_ads
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.ops_staff WHERE user_id = auth.uid() AND role IN ('admin', 'operator'))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.ops_staff WHERE user_id = auth.uid() AND role IN ('admin', 'operator'))
  );

-- Index for common queries
CREATE INDEX IF NOT EXISTS idx_fan_ads_status ON public.fan_ads(status);
CREATE INDEX IF NOT EXISTS idx_fan_ads_fan_user ON public.fan_ads(fan_user_id);
CREATE INDEX IF NOT EXISTS idx_fan_ads_dates ON public.fan_ads(start_date, end_date) WHERE status = 'active';

COMMIT;
