-- =====================================================
-- Migration: 019_fix_dt_purchases_updated_at.sql
-- Purpose: Add updated_at column to dt_purchases table
-- Description: The column was referenced in 010_payment_atomicity.sql
--              but was not defined in 006_wallet_ledger.sql
-- =====================================================

-- 1. Add updated_at column if not exists
ALTER TABLE dt_purchases
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- 2. Backfill existing records
UPDATE dt_purchases
SET updated_at = COALESCE(paid_at, cancelled_at, refunded_at, created_at)
WHERE updated_at IS NULL;

-- 3. Create trigger for automatic update
DROP TRIGGER IF EXISTS update_dt_purchases_updated_at ON dt_purchases;

CREATE TRIGGER update_dt_purchases_updated_at
  BEFORE UPDATE ON dt_purchases
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- 4. Add comment
COMMENT ON COLUMN dt_purchases.updated_at IS 'Last modification timestamp, automatically updated by trigger';
