-- =====================================================
-- Migration: 014_admin_policies.sql
-- Purpose: Add missing admin RLS policies
-- Description: Enables admin access to tables that
--              were missing admin policies
-- =====================================================

-- =====================================================
-- 1. HELPER FUNCTION: Check Admin Role
-- =====================================================

-- Create a cached function to check admin status
CREATE OR REPLACE FUNCTION public.is_admin(p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = p_user_id AND role = 'admin'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_admin TO authenticated;

-- =====================================================
-- 2. MESSAGES TABLE - Admin Policies
-- =====================================================

-- Admin can view all messages (for moderation)
CREATE POLICY "Admins can view all messages"
  ON messages FOR SELECT
  USING (public.is_admin());

-- Admin can delete any message (moderation)
CREATE POLICY "Admins can delete any message"
  ON messages FOR DELETE
  USING (public.is_admin());

-- Admin can update messages (edit, pin, etc.)
CREATE POLICY "Admins can update any message"
  ON messages FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- 3. SUBSCRIPTIONS TABLE - Admin Policies
-- =====================================================

-- Admin can view all subscriptions
CREATE POLICY "Admins can view all subscriptions"
  ON subscriptions FOR SELECT
  USING (public.is_admin());

-- Admin can manage subscriptions (extend, cancel, etc.)
CREATE POLICY "Admins can manage subscriptions"
  ON subscriptions FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- 4. REPLY_QUOTA TABLE - Admin Policies
-- =====================================================

-- Admin can view all quotas
CREATE POLICY "Admins can view all reply quotas"
  ON reply_quota FOR SELECT
  USING (public.is_admin());

-- Admin can manage quotas (reset, adjust)
CREATE POLICY "Admins can manage reply quotas"
  ON reply_quota FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- 5. DT_PURCHASES TABLE - Admin Policies
-- =====================================================

-- Admin can view all purchases (finance oversight)
CREATE POLICY "Admins can view all purchases"
  ON dt_purchases FOR SELECT
  USING (public.is_admin());

-- Admin can update purchase status (refunds, corrections)
CREATE POLICY "Admins can update purchases"
  ON dt_purchases FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- 6. LEDGER_ENTRIES TABLE - Admin Policies
-- =====================================================

-- Admin can view all ledger entries (audit)
CREATE POLICY "Admins can view all ledger entries"
  ON ledger_entries FOR SELECT
  USING (public.is_admin());

-- =====================================================
-- 7. DT_DONATIONS TABLE - Admin Policies
-- =====================================================

-- Admin can view all donations
CREATE POLICY "Admins can view all donations"
  ON dt_donations FOR SELECT
  USING (public.is_admin());

-- =====================================================
-- 8. WALLETS TABLE - Admin Policies
-- =====================================================

-- Admin can view all wallets
CREATE POLICY "Admins can view all wallets"
  ON wallets FOR SELECT
  USING (public.is_admin());

-- Admin can update wallets (balance corrections)
CREATE POLICY "Admins can update wallets"
  ON wallets FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- 9. USER_PROFILES TABLE - Admin Policies
-- =====================================================

-- Admin can view all user profiles
CREATE POLICY "Admins can view all user profiles"
  ON user_profiles FOR SELECT
  USING (public.is_admin());

-- Admin can update any user profile (ban, role change)
CREATE POLICY "Admins can update any user profile"
  ON user_profiles FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- 10. CREATOR_PROFILES TABLE - Admin Policies
-- =====================================================

-- Admin can view all creator profiles (including unverified)
CREATE POLICY "Admins can view all creator profiles"
  ON creator_profiles FOR SELECT
  USING (public.is_admin());

-- Admin can update creator profiles (verification, etc.)
CREATE POLICY "Admins can update any creator profile"
  ON creator_profiles FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- 11. CHANNELS TABLE - Admin Policies
-- =====================================================

-- Admin can view all channels
CREATE POLICY "Admins can view all channels"
  ON channels FOR SELECT
  USING (public.is_admin());

-- Admin can manage channels
CREATE POLICY "Admins can manage channels"
  ON channels FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- 12. BACKGROUND_JOBS TABLE - Admin Policies
-- =====================================================

-- Admin can view background jobs
CREATE POLICY "Admins can view background jobs"
  ON background_jobs FOR SELECT
  USING (public.is_admin());

-- =====================================================
-- 13. PRIVATE_CARDS TABLE - Admin Policies
-- =====================================================

-- Admin can view all private cards
CREATE POLICY "Admins can view all private cards"
  ON private_cards FOR SELECT
  USING (public.is_admin());

-- Admin can manage private cards
CREATE POLICY "Admins can manage private cards"
  ON private_cards FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- 14. ADMIN AUDIT LOG
-- =====================================================

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID NOT NULL REFERENCES auth.users(id),
  action TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID,
  old_data JSONB,
  new_data JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_admin
  ON admin_audit_log(admin_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_table
  ON admin_audit_log(table_name, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_record
  ON admin_audit_log(record_id)
  WHERE record_id IS NOT NULL;

-- RLS for audit log (admins only)
ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view audit log"
  ON admin_audit_log FOR SELECT
  USING (public.is_admin());

CREATE POLICY "System can insert audit log"
  ON admin_audit_log FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- 15. AUDIT LOG FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION public.log_admin_action(
  p_action TEXT,
  p_table_name TEXT,
  p_record_id UUID DEFAULT NULL,
  p_old_data JSONB DEFAULT NULL,
  p_new_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO admin_audit_log (
    admin_user_id,
    action,
    table_name,
    record_id,
    old_data,
    new_data
  )
  VALUES (
    auth.uid(),
    p_action,
    p_table_name,
    p_record_id,
    p_old_data,
    p_new_data
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.log_admin_action TO authenticated;

COMMENT ON FUNCTION public.is_admin IS
'Checks if the given user (or current user) has admin role. Results are cached within the same query.';

COMMENT ON TABLE admin_audit_log IS
'Audit log tracking all admin actions for compliance and security review.';
