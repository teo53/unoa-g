-- =====================================================
-- Migration: 068_fix_message_delivery_rls.sql
-- WI-1A: Harden message_delivery RLS to own-row only
-- Purpose: Close permissive INSERT hole that allows any
--          authenticated user to insert for any user_id
-- =====================================================

-- 1) DROP existing overly-permissive policies
DROP POLICY IF EXISTS "Users can view own delivery status" ON message_delivery;
DROP POLICY IF EXISTS "Users can update own read status" ON message_delivery;
DROP POLICY IF EXISTS "System can create delivery" ON message_delivery;

-- 2) CREATE 3 own-row policies (TO authenticated explicit)

-- SELECT: user can only see their own delivery records
CREATE POLICY "delivery_select_own"
  ON message_delivery
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- INSERT: user can only insert records for themselves
-- (supports upsert / INSERT ... ON CONFLICT paths used by markAsRead)
CREATE POLICY "delivery_insert_own"
  ON message_delivery
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- UPDATE: user can only update their own read status
CREATE POLICY "delivery_update_own"
  ON message_delivery
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- 3) Assert: no unexpected policies remain
DO $$
DECLARE
  v_policy_count INT;
  v_expected_names TEXT[] := ARRAY[
    'delivery_select_own',
    'delivery_insert_own',
    'delivery_update_own'
  ];
  v_actual_names TEXT[];
BEGIN
  SELECT array_agg(policyname ORDER BY policyname)
  INTO v_actual_names
  FROM pg_policies
  WHERE tablename = 'message_delivery'
    AND schemaname = 'public';

  v_policy_count := COALESCE(array_length(v_actual_names, 1), 0);

  IF v_policy_count != 3 THEN
    RAISE EXCEPTION 'message_delivery: expected 3 policies, found %. Policies: %',
      v_policy_count, v_actual_names;
  END IF;

  -- Verify each expected policy exists
  FOR i IN 1..3 LOOP
    IF NOT (v_expected_names[i] = ANY(v_actual_names)) THEN
      RAISE EXCEPTION 'message_delivery: missing expected policy "%". Found: %',
        v_expected_names[i], v_actual_names;
    END IF;
  END LOOP;

  RAISE NOTICE 'OK: message_delivery has exactly 3 own-row policies';
END $$;
