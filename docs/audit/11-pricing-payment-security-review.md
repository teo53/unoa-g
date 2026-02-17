# 11. Pricing / Payment / Security Review

> Date: 2026-02-17 | Sprint: Phase 1-5 + WI-6/WI-보완

---

## 1. Scope

| Area | Description |
|------|-------------|
| Platform pricing | IAP price differentiation (web/android/ios) |
| Checkout flow | `payment-checkout` Edge Function security hardening |
| Subscription pricing | Creator-controlled price multipliers (WI-6) |
| Hardcoded values | Tax rates, tier prices in admin UI |

---

## 2. Changes Implemented

### 2.1 Platform-Aware Pricing

**Files**: `business_config.dart`, `business-config.ts`, `platform_pricing.dart`

| Platform | Markup | Example (BASIC) | Rationale |
|----------|--------|-----------------|-----------|
| Web | Base | 4,900 | Direct payment, no store commission |
| Android | ~20% | 5,900 | Google Play 15-30% commission |
| iOS | ~30% | 6,900 | Apple 15-30% commission |

- `PurchasePlatform` enum added to Flutter (`business_config.dart` L5-7)
- `tierPricesByPlatform` and `dtPackagesByPlatform` maps added to both Flutter and TypeScript configs
- `purchasePlatformProvider` (Riverpod) auto-detects platform via `kIsWeb` + `defaultTargetPlatform`

### 2.2 Checkout Security (payment-checkout)

**File**: `supabase/functions/payment-checkout/index.ts`

| Change | Before | After |
|--------|--------|-------|
| Package pricing | Single `priceKrw` per package | `prices: { web, android, ios }` per package |
| Platform param | Not accepted | `platform` from body, validated against `['web','android','ios']` |
| Origin check | None | `platform=web` → `isAllowedOrigin(req.headers.Origin)`, 403 if invalid |
| Audit trail | `payment_provider: 'tosspayments'` | `payment_provider: 'tosspayments\|{platformKey}'` (pipe-delimited) |
| Price resolution | `pkg.priceKrw` | `pkg.prices[platformKey]` |

**Security considerations**:
- Origin validation only applies to `web` platform (mobile apps don't send Origin headers reliably)
- `isAllowedOrigin()` uses CORS whitelist from `_shared/cors.ts` (6 production + 4 dev origins)
- No DB schema change required — `payment_provider` is TEXT type, `|` delimiter is backward-compatible

### 2.3 Creator Pricing Policy (WI-6)

**Files**: `supabase/functions/subscription-pricing/index.ts`, `subscription_pricing_provider.dart`, `creator_profile_edit_screen.dart`

| Preset | Multiplier | Label |
|--------|------------|-------|
| support | 0.9x | 팬 우선 (10% 할인) |
| standard | 1.0x | 기본가 |
| premium | 1.1x | 프리미엄 (10% 추가) |

- Stored in `policy_config` table (key: `subscription_pricing:{channelId}`)
- No DB migration needed (existing `policy_config` table)
- Price rounding: `round(base * multiplier / 100) * 100` (100원 단위)
- Edge Function validates JWT + channel ownership before upsert
- Demo mode: returns default `standard` policy

### 2.4 Hardcoded Value Fixes (Step 3)

| File | Line | Before | After |
|------|------|--------|-------|
| `settlements-client.tsx` | L586-588 | `'사업소득 3.3%'`, `'기타소득 8.8%'` | `businessConfig.taxRates.businessIncome/otherIncome` |
| `creator-detail-client.tsx` | L347,356,365 | `* 4900`, `* 9900`, `* 19900` | `businessConfig.tierPrices.BASIC/STANDARD/VIP` |

---

## 3. Web Purchase Pages

### `/pricing` (Subscription Comparison)

- 3-column tier comparison (BASIC / STANDARD / VIP)
- Shows web prices from `businessConfig.tierPricesByPlatform.web`
- Reply token rules from `businessConfig.tokenRules`
- Character limit progression timeline
- "Why cheaper on web?" section explaining IAP markup
- Legal notices: auto-renewal, refund policy

### `/store/dt` (DT Token Store)

- 6 DT packages from `businessConfig.dtPackagesByPlatform`
- Web prices displayed; savings vs iOS shown
- Checkout via `checkout-service.ts` → `payment-checkout` Edge Function
- Demo mode: mock checkout URL

---

## 4. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Price manipulation via platform spoofing | Medium | Origin check for web; mobile IAP validates through store |
| Creator sets extreme pricing | Low | Only 3 fixed presets (0.9x / 1.0x / 1.1x), no arbitrary values |
| iOS price comparison showing web prices | Medium | Must NOT show web comparison on iOS (Apple anti-steering policy) |
| Audit trail parsing complexity | Low | Simple `split('|')` on `payment_provider` field |
| Demo mode bypasses pricing | Info | Acceptable — demo data is mock only |

---

## 5. Verification Checklist

- [ ] `PurchasePlatform.web` prices match existing `tierPricesKrw` (backward compatible)
- [ ] `/pricing` renders 3-column comparison with web prices
- [ ] `/store/dt` renders 6 packages with web prices
- [ ] `payment-checkout`: web + allowed Origin → 200
- [ ] `payment-checkout`: web + disallowed Origin → 403
- [ ] `payment-checkout`: android/ios → skips Origin check
- [ ] `subscription-pricing` GET returns default policy for unconfigured channel
- [ ] `subscription-pricing` PUT: non-owner → 403
- [ ] `subscription-pricing` PUT: owner → upserts `policy_config`
- [ ] `TierComparisonSheet`: multiplier=1.0 → normal prices
- [ ] `TierComparisonSheet`: multiplier=0.9 → discounted with strikethrough
- [ ] Creator profile edit: pricing preset radio buttons work
- [ ] Admin settlements: tax rate labels from config, not hardcoded
- [ ] Admin creator detail: tier revenue from config, not hardcoded
- [ ] Demo mode: all features work with mock data
- [ ] No DB schema changes required
