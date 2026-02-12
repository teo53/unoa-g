-- =====================================================
-- Migration: 027_add_reports_and_blocks.sql
-- Purpose: Add missing helper functions for reports and blocks
-- Note: reports and user_blocks tables already exist from 026
-- =====================================================

-- Helper: Check if current user is blocked by another user
CREATE OR REPLACE FUNCTION public.is_blocked_by(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_blocks
    WHERE blocker_id = p_user_id
      AND blocked_id = auth.uid()
  );
$$;

-- Helper: Get list of users that current user has blocked
CREATE OR REPLACE FUNCTION public.get_blocked_users()
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT blocked_id FROM user_blocks
  WHERE blocker_id = auth.uid();
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.is_blocked_by(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_blocked_users() TO authenticated;
