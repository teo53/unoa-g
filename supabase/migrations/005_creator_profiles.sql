-- ============================================
-- UNO A - Creator Profiles Schema
-- Version: 1.1.0
-- ============================================

-- ============================================
-- 1. CREATOR PROFILES (extends user_profiles)
-- ============================================
CREATE TABLE IF NOT EXISTS public.creator_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  channel_id UUID REFERENCES channels(id),

  -- Display info
  stage_name TEXT NOT NULL,
  stage_name_en TEXT,
  profile_image_url TEXT,
  cover_image_url TEXT,
  short_bio TEXT,
  full_bio TEXT,

  -- Categories/Tags (아이돌, 배우, 가수, 인플루언서, etc.)
  category TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',

  -- Social links
  social_links JSONB DEFAULT '{
    "instagram": null,
    "twitter": null,
    "youtube": null,
    "tiktok": null,
    "weverse": null,
    "vlive": null
  }',

  -- Verification & Onboarding
  onboarding_completed BOOLEAN DEFAULT false,
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
  verified_at TIMESTAMPTZ,
  verification_documents JSONB DEFAULT '[]',

  -- Payout info (encrypted in production)
  bank_code TEXT,
  bank_name TEXT,
  bank_account_number TEXT, -- Should be encrypted in production
  account_holder_name TEXT,
  resident_registration_number TEXT, -- 주민등록번호 (should be encrypted)
  business_registration_number TEXT, -- 사업자등록번호 (optional, for business accounts)

  -- Tax settings
  withholding_tax_rate NUMERIC DEFAULT 0.033, -- 3.3% default for Korea
  tax_type TEXT DEFAULT 'individual' CHECK (tax_type IN ('individual', 'business')),
  payout_verified BOOLEAN DEFAULT false,
  payout_verified_at TIMESTAMPTZ,

  -- Stats (materialized/cached for performance)
  total_subscribers INT DEFAULT 0,
  total_messages_sent INT DEFAULT 0,
  total_revenue_dt BIGINT DEFAULT 0,
  total_revenue_krw BIGINT DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_creator_profiles_user ON creator_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_creator_profiles_channel ON creator_profiles(channel_id);
CREATE INDEX IF NOT EXISTS idx_creator_profiles_verification ON creator_profiles(verification_status);
CREATE INDEX IF NOT EXISTS idx_creator_profiles_category ON creator_profiles USING GIN(category);

-- ============================================
-- 2. CREATOR MANAGERS (multi-admin support)
-- ============================================
CREATE TABLE IF NOT EXISTS public.creator_managers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_profile_id UUID NOT NULL REFERENCES creator_profiles(id) ON DELETE CASCADE,
  manager_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Permissions
  permissions JSONB NOT NULL DEFAULT '{
    "broadcast": true,
    "inbox": true,
    "analytics": false,
    "payout": false,
    "settings": false
  }',

  -- Invitation tracking
  invited_by UUID REFERENCES auth.users(id),
  invited_at TIMESTAMPTZ DEFAULT now(),
  accepted_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_creator_manager UNIQUE(creator_profile_id, manager_user_id)
);

CREATE INDEX IF NOT EXISTS idx_creator_managers_creator ON creator_managers(creator_profile_id);
CREATE INDEX IF NOT EXISTS idx_creator_managers_user ON creator_managers(manager_user_id);

-- ============================================
-- 3. CREATOR SETTINGS (Room type, welcome chat, etc.)
-- ============================================
CREATE TABLE IF NOT EXISTS public.creator_settings (
  creator_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Room Type (from Fancim "방 타입")
  -- broadcast_only: Fans cannot message unless using Paid Reply
  -- limited: Default N messages/day per fan
  -- open: No limits (still rate-limited for spam)
  room_type TEXT DEFAULT 'limited' CHECK (room_type IN ('broadcast_only', 'limited', 'open')),
  fan_daily_limit INT DEFAULT 3,

  -- Paid Reply settings
  paid_reply_enabled BOOLEAN DEFAULT true,
  paid_reply_price_dt INT DEFAULT 10,

  -- Welcome Chat (from Fancim "웰컴채팅")
  auto_welcome_enabled BOOLEAN DEFAULT true,
  welcome_message TEXT DEFAULT '안녕하세요! 제 채널에 와주셔서 감사합니다. 보내주시는 채팅은 저에게만 보이니 편하게 채팅 많이 쳐주세요! 즐거운 채팅을 위해 부드럽고 둥근 언어 사용을 부탁드려요 :)',
  welcome_media_url TEXT,
  welcome_media_type TEXT CHECK (welcome_media_type IN ('image', 'video', NULL)),

  -- Chat decoration (from Fancim "채팅방 꾸미기")
  chat_background_url TEXT,
  chat_theme_color TEXT DEFAULT '#FF3B30',

  -- Notification settings
  notify_new_subscriber BOOLEAN DEFAULT true,
  notify_donation BOOLEAN DEFAULT true,
  notify_reply BOOLEAN DEFAULT true,

  -- Rate limiting
  fan_message_cooldown_seconds INT DEFAULT 60, -- Min seconds between fan messages

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 4. RLS POLICIES
-- ============================================
ALTER TABLE creator_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_managers ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_settings ENABLE ROW LEVEL SECURITY;

-- Creator Profiles policies
CREATE POLICY "Public can view verified creators"
  ON creator_profiles FOR SELECT
  USING (verification_status = 'verified');

CREATE POLICY "Creators can view own profile"
  ON creator_profiles FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Creators can update own profile"
  ON creator_profiles FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can create creator profile"
  ON creator_profiles FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Creator Managers policies
CREATE POLICY "Creator can manage own managers"
  ON creator_managers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM creator_profiles cp
      WHERE cp.id = creator_managers.creator_profile_id
        AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "Managers can view own assignment"
  ON creator_managers FOR SELECT
  USING (manager_user_id = auth.uid());

-- Creator Settings policies
CREATE POLICY "Creator can manage own settings"
  ON creator_settings FOR ALL
  USING (creator_id = auth.uid());

CREATE POLICY "Fans can view creator settings (limited)"
  ON creator_settings FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- ============================================
-- 5. TRIGGERS
-- ============================================

-- Update updated_at on creator_profiles
DROP TRIGGER IF EXISTS update_creator_profiles_updated_at ON creator_profiles;
CREATE TRIGGER update_creator_profiles_updated_at
  BEFORE UPDATE ON creator_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Update updated_at on creator_settings
DROP TRIGGER IF EXISTS update_creator_settings_updated_at ON creator_settings;
CREATE TRIGGER update_creator_settings_updated_at
  BEFORE UPDATE ON creator_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Auto-create channel when creator profile is created
CREATE OR REPLACE FUNCTION public.handle_new_creator_profile()
RETURNS TRIGGER AS $$
DECLARE
  new_channel_id UUID;
BEGIN
  -- Create channel for creator
  INSERT INTO channels (artist_id, name, description, avatar_url)
  VALUES (
    NEW.user_id,
    NEW.stage_name,
    NEW.short_bio,
    NEW.profile_image_url
  )
  RETURNING id INTO new_channel_id;

  -- Update creator profile with channel_id
  NEW.channel_id := new_channel_id;

  -- Create default settings
  INSERT INTO creator_settings (creator_id)
  VALUES (NEW.user_id)
  ON CONFLICT (creator_id) DO NOTHING;

  -- Update user_profiles role to creator
  UPDATE user_profiles
  SET role = 'creator', updated_at = now()
  WHERE id = NEW.user_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_creator_profile_created ON creator_profiles;
CREATE TRIGGER on_creator_profile_created
  BEFORE INSERT ON creator_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_creator_profile();

-- ============================================
-- 6. HELPER FUNCTIONS
-- ============================================

-- Get creator profile by user_id
CREATE OR REPLACE FUNCTION public.get_creator_profile(p_user_id UUID)
RETURNS creator_profiles AS $$
  SELECT * FROM creator_profiles WHERE user_id = p_user_id;
$$ LANGUAGE sql STABLE;

-- Check if user is a manager for a creator
CREATE OR REPLACE FUNCTION public.is_manager_for_creator(p_user_id UUID, p_creator_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM creator_managers cm
    JOIN creator_profiles cp ON cp.id = cm.creator_profile_id
    WHERE cm.manager_user_id = p_user_id
      AND cp.user_id = p_creator_user_id
      AND cm.accepted_at IS NOT NULL
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- Check if user has specific permission for a creator
CREATE OR REPLACE FUNCTION public.has_creator_permission(
  p_user_id UUID,
  p_creator_user_id UUID,
  p_permission TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  perms JSONB;
BEGIN
  -- Creator always has all permissions
  IF p_user_id = p_creator_user_id THEN
    RETURN true;
  END IF;

  -- Check manager permissions
  SELECT permissions INTO perms
  FROM creator_managers cm
  JOIN creator_profiles cp ON cp.id = cm.creator_profile_id
  WHERE cm.manager_user_id = p_user_id
    AND cp.user_id = p_creator_user_id
    AND cm.accepted_at IS NOT NULL;

  IF perms IS NULL THEN
    RETURN false;
  END IF;

  RETURN COALESCE((perms->>p_permission)::BOOLEAN, false);
END;
$$ LANGUAGE plpgsql STABLE;
