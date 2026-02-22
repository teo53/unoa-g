# P0 Security Fixes — Verification Plan

**Migration**: `102_security_audit_p0_fixes.sql`
**Branch**: `claude/security-payment-hardening-nM5WY`
**Date**: 2026-02-22

---

## 1. RLS: user_presence SELECT

### Risk
Migration 007 created `"Users can view presence of their channel connections"` with `USING (auth.uid() IS NOT NULL)`, allowing any authenticated user to enumerate all online users and which channels they are viewing.

### Fix
Replaced with `"Channel members can view presence"` — restricts to:
- Own presence row
- Channel artist viewing their channel's viewers
- Active subscribers viewing co-subscribers in same channel

### Verification SQL

```sql
-- Setup: Two users (user_A = subscriber of channel_X, user_B = not subscriber)
-- As user_B:
SET request.jwt.claims = '{"sub": "<user_B_id>", "role": "authenticated"}';
SELECT * FROM user_presence WHERE channel_id = '<channel_X_id>';
-- EXPECTED: 0 rows (user_B is not subscribed to channel_X)

-- As user_A (subscriber of channel_X):
SET request.jwt.claims = '{"sub": "<user_A_id>", "role": "authenticated"}';
SELECT * FROM user_presence WHERE channel_id = '<channel_X_id>';
-- EXPECTED: rows for users with presence in channel_X

-- Negative: user_A cannot see presence in channel_Y they don't subscribe to
SELECT * FROM user_presence WHERE channel_id = '<channel_Y_id>';
-- EXPECTED: 0 rows (unless user_A is also subscribed to channel_Y)
```

---

## 2. RLS: message_reactions SELECT

### Risk
Migration 007 created `"Users can view reactions"` with `USING (auth.uid() IS NOT NULL)`. Migration 028 added the correct channel-scoped policy but never dropped the 007 policy. PostgreSQL ORs permissive policies, so the open one wins.

### Fix
Dropped `"Users can view reactions"`, `"Users can add reactions"`, and `"Users can remove own reactions"` (007 names). Re-created 028's channel-scoped policies.

### Verification SQL

```sql
-- Setup: message_M in channel_X. user_B is NOT subscribed to channel_X.
-- As user_B:
SET request.jwt.claims = '{"sub": "<user_B_id>", "role": "authenticated"}';
SELECT * FROM message_reactions WHERE message_id = '<message_M_id>';
-- EXPECTED: 0 rows (user_B not subscribed to channel_X)

-- As channel_X artist:
SET request.jwt.claims = '{"sub": "<artist_id>", "role": "authenticated"}';
SELECT * FROM message_reactions WHERE message_id = '<message_M_id>';
-- EXPECTED: all reactions on that message

-- As active subscriber of channel_X:
SET request.jwt.claims = '{"sub": "<subscriber_id>", "role": "authenticated"}';
SELECT * FROM message_reactions WHERE message_id = '<message_M_id>';
-- EXPECTED: all reactions on that message
```

---

## 3. admin_audit_log INSERT

### Risk
Migration 014 created `"System can insert audit log"` with `WITH CHECK (true)`, allowing any authenticated user to insert arbitrary audit entries.

### Fix (layered, across 026/101/102)
1. Migration 026: Dropped permissive policy, created `"Secure audit log insert"` (service_role OR is_admin)
2. Migration 101: Revoked EXECUTE on `log_admin_action` from authenticated
3. Migration 102: Defensive DROP IF EXISTS for old policy name

### Verification SQL

```sql
-- As authenticated non-admin user:
SET request.jwt.claims = '{"sub": "<regular_user_id>", "role": "authenticated"}';
INSERT INTO admin_audit_log (admin_user_id, action, table_name)
VALUES ('<regular_user_id>', 'test', 'test');
-- EXPECTED: ERROR (RLS violation — not service_role and not admin)

-- As service_role (Edge Function):
-- (Run via supabase client with service_role key)
INSERT INTO admin_audit_log (admin_user_id, action, table_name)
VALUES ('00000000-0000-0000-0000-000000000000', 'system_test', 'test');
-- EXPECTED: SUCCESS

-- Verify log_admin_action is not callable by authenticated:
SET request.jwt.claims = '{"sub": "<regular_user_id>", "role": "authenticated"}';
SELECT log_admin_action('test', 'test');
-- EXPECTED: ERROR (permission denied — EXECUTE revoked in migration 101)
```

---

## 4. SECURITY DEFINER — SET search_path

### Risk
15+ functions from migrations 003-007 and 026 (encrypt/decrypt) used SECURITY DEFINER without `SET search_path = public`. This allows search_path injection attacks where an attacker creates same-named tables in a schema earlier in the search_path.

### Fix
`ALTER FUNCTION ... SET search_path = public` for all affected functions (idempotent, no signature change).

### Verification SQL

```sql
-- Check all SECURITY DEFINER functions have search_path set:
SELECT
  p.proname AS function_name,
  n.nspname AS schema,
  p.proconfig AS config
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.prosecdef = true
  AND n.nspname = 'public'
ORDER BY p.proname;
-- EXPECTED: Every row should have 'search_path=public' in proconfig array.
-- If any SECURITY DEFINER function has NULL proconfig or missing search_path,
-- it needs to be added.

-- Specific spot checks:
SELECT proconfig FROM pg_proc WHERE proname = 'refresh_reply_quotas';
-- EXPECTED: contains 'search_path=public'

SELECT proconfig FROM pg_proc WHERE proname = 'encrypt_sensitive';
-- EXPECTED: contains 'search_path=public'

SELECT proconfig FROM pg_proc WHERE proname = 'handle_new_user';
-- EXPECTED: contains 'search_path=public'
```

---

## 5. Payment: PortOne returns pending (no false success)

### Risk
`PortOnePaymentService.requestPayment()` returned `success: true` after checkout initiation, before the payment was server-verified. FundingCheckoutScreen treated this as "paid" and immediately created the pledge.

### Fix
- `PaymentResult` now enforces invariants via factory constructors:
  - `.confirmed(paymentId)` — server verified
  - `.pending(paymentId)` — checkout initiated, not yet paid
  - `.rejected(message)` — failed
- `PortOnePaymentService` returns `.pending()` instead of `.confirmed()`
- `DemoPaymentService` returns `.confirmed()` (demo mode simulates full flow)
- `FundingCheckoutScreen` checks `isRejected` first, then proceeds to Edge Function verification (which verifies with PortOne API before creating pledge)

### Manual Test Steps

1. **Demo mode**: Select funding tier → checkout → expect success (confirmed directly)
2. **Production (web)**: Select funding tier → PortOne popup → complete payment →
   - Edge Function verifies with PortOne API
   - If verified: pledge created, success screen
   - If not verified: error screen
3. **Edge case**: PortOne popup → user closes popup → Edge Function call with unverified payment →
   - `"Payment verification failed"` error
   - No pledge created
4. **DT purchase (web)**: Select package → PortOne/Toss window opens →
   - Wallet reloads after returning (existing flow)
   - Webhook/confirm/reconcile handles actual crediting

---

## 6. Media: Image OOM guard

### Risk
`compressImageWithThumbnail()` called `file.readAsBytes()` before any size check, potentially loading arbitrarily large files into memory.

### Fix
Added `file.length()` check before `readAsBytes()`, using the same `maxImageSize` (10 MB) constant already used for post-compression validation.

### Manual Test Steps

1. Pick an image > 10 MB → expect `StateError` with Korean size limit message
2. Pick an image < 10 MB → expect normal compression and upload
3. Video/voice uploads already had pre-read size checks (no change needed)

---

## 7. Storage: signed-URL toggle driven by AppConfig

### Risk
`MediaUrlResolver.useSignedUrls` was a static `false` never wired to `AppConfig.usePrivateStorageBucket`. Switching the storage bucket to private would not automatically enable signed URLs.

### Fix
Added `MediaUrlResolver.useSignedUrls = AppConfig.usePrivateStorageBucket` in `main.dart` initialization, before any media operations.

### Verification

1. Build with `--dart-define=USE_PRIVATE_STORAGE=true`
2. Verify `MediaUrlResolver.useSignedUrls == true`
3. Media loading uses `createSignedUrl()` instead of `getPublicUrl()`
4. Build with default (no flag) → `useSignedUrls == false` → public URLs

---

## Files Changed

| File | Change | Why |
|------|--------|-----|
| `lib/services/payment_service.dart` | `PaymentResult` with factory constructors; `PortOnePaymentService` returns pending | Prevent false payment success |
| `lib/services/payment_confirmation_service.dart` | New file: polling + funding result interpretation | Centralized confirmation logic |
| `lib/features/funding/funding_checkout_screen.dart` | Handle `isRejected`/`isPending`; use confirmation service | No premature success |
| `lib/services/media_service.dart` | Pre-read size check in `compressImageWithThumbnail` | OOM guard |
| `lib/main.dart` | Wire `useSignedUrls` to `AppConfig` | Storage security |
| `supabase/migrations/102_security_audit_p0_fixes.sql` | RLS fixes + SET search_path | Database hardening |
