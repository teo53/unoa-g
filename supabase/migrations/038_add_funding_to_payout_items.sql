-- Migration: Add 'funding' to payout_line_items and ledger_entries CHECK constraints
-- This allows funding pledges to be included in creator payout calculations

-- 1. Drop and recreate payout_line_items.item_type CHECK constraint
ALTER TABLE payout_line_items
  DROP CONSTRAINT IF EXISTS payout_line_items_item_type_check;

ALTER TABLE payout_line_items
  ADD CONSTRAINT payout_line_items_item_type_check
  CHECK (item_type IN (
    'tip',
    'paid_reply',
    'private_card',
    'chat_ticket',
    'challenge',
    'funding'
  ));

-- 2. Drop and recreate ledger_entries.entry_type CHECK constraint
ALTER TABLE ledger_entries
  DROP CONSTRAINT IF EXISTS ledger_entries_entry_type_check;

ALTER TABLE ledger_entries
  ADD CONSTRAINT ledger_entries_entry_type_check
  CHECK (entry_type IN (
    'purchase',
    'tip',
    'paid_reply',
    'private_card',
    'refund',
    'payout',
    'adjustment',
    'bonus',
    'subscription',
    'funding'
  ));
