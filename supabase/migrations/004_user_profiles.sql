-- ============================================
-- UNO A - User Profiles Schema
-- Version: 1.1.0
-- ============================================

-- ============================================
-- 1. USER PROFILES (extends auth.users)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'fan' CHECK (role IN ('fan', 'creator', 'creator_manager', 'admin')),
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,

  -- Age verification
  date_of_birth DATE,
  age_verified_at TIMESTAMPTZ,
  guardian_consent_at TIMESTAMPTZ, -- For under-14
  guardian_phone TEXT,

  -- Contact
  phone TEXT,
  email_verified BOOLEAN DEFAULT false,

  -- Preferences
  locale TEXT DEFAULT 'ko-KR',
  timezone TEXT DEFAULT 'Asia/Seoul',
  notification_settings JSONB DEFAULT '{
    "push_enabled": true,
    "broadcast_notifications": true,
    "donation_notifications": true,
    "marketing_notifications": false
  }',

  -- Moderation
  is_banned BOOLEAN DEFAULT false,
  banned_at TIMESTAMPTZ,
  ban_reason TEXT,
  ban_expires_at TIMESTAMPTZ,

  -- Metadata
  last_active_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_banned ON user_profiles(is_banned) WHERE is_banned = true;
CREATE INDEX IF NOT EXISTS idx_user_profiles_display_name ON user_profiles(display_name);

-- ============================================
-- 2. RLS POLICIES FOR USER PROFILES
-- ============================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (id = auth.uid());

-- Public profile info visible to authenticated users (limited fields via view)
CREATE POLICY "Authenticated can view public profiles"
  ON user_profiles FOR SELECT
  USING (auth.uid() IS NOT NULL AND is_banned = false);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (id = auth.uid());

-- Admins can do everything
CREATE POLICY "Admins can manage all profiles"
  ON user_profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid() AND up.role = 'admin'
    )
  );

-- ============================================
-- 3. TRIGGER: Auto-create profile on signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'display_name', 'User'),
    NEW.raw_user_meta_data->>'avatar_url'
  );

  -- Also create wallet for new user
  INSERT INTO public.wallets (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 4. TRIGGER: Update updated_at timestamp
-- ============================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- 5. HELPER FUNCTIONS
-- ============================================

-- Check if user is under 14 (requires guardian consent)
CREATE OR REPLACE FUNCTION public.is_minor_under_14(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  user_dob DATE;
  age_years INTEGER;
BEGIN
  SELECT date_of_birth INTO user_dob
  FROM user_profiles
  WHERE id = p_user_id;

  IF user_dob IS NULL THEN
    RETURN NULL; -- Age not verified
  END IF;

  age_years := EXTRACT(YEAR FROM age(user_dob));
  RETURN age_years < 14;
END;
$$ LANGUAGE plpgsql STABLE;

-- Check if user is under 19 (requires guardian consent for payments in Korea)
CREATE OR REPLACE FUNCTION public.is_minor_under_19(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  user_dob DATE;
  age_years INTEGER;
BEGIN
  SELECT date_of_birth INTO user_dob
  FROM user_profiles
  WHERE id = p_user_id;

  IF user_dob IS NULL THEN
    RETURN NULL; -- Age not verified
  END IF;

  age_years := EXTRACT(YEAR FROM age(user_dob));
  RETURN age_years < 19;
END;
$$ LANGUAGE plpgsql STABLE;

-- Check if user can make payments
CREATE OR REPLACE FUNCTION public.can_user_make_payment(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  profile RECORD;
BEGIN
  SELECT * INTO profile
  FROM user_profiles
  WHERE id = p_user_id;

  IF profile IS NULL THEN
    RETURN false;
  END IF;

  -- Check if banned
  IF profile.is_banned THEN
    RETURN false;
  END IF;

  -- If under 19, check guardian consent
  IF is_minor_under_19(p_user_id) THEN
    RETURN profile.guardian_consent_at IS NOT NULL;
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql STABLE;
