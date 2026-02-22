-- =====================================================
-- Migration: 101_revoke_audit_log_execute.sql
-- Purpose: Revoke log_admin_action EXECUTE from authenticated (P0-5)
--
-- Background:
--   Migration 014 granted EXECUTE ON log_admin_action TO authenticated.
--   Migration 026 hardened the function body with admin/service_role checks,
--   but never revoked the EXECUTE grant itself.
--
-- Fix:
--   Defense-in-depth: non-admin callers already get an exception from the
--   function body, but revoking the grant blocks the call at the permission
--   layer before the function even executes.
-- =====================================================

-- Revoke from all non-service roles
REVOKE EXECUTE ON FUNCTION public.log_admin_action(TEXT, TEXT, UUID, JSONB, JSONB)
  FROM authenticated, anon, PUBLIC;

-- Ensure only service_role can call it
GRANT EXECUTE ON FUNCTION public.log_admin_action(TEXT, TEXT, UUID, JSONB, JSONB)
  TO service_role;
