# 12. FastAPI BFF Migration Assessment

> Date: 2026-02-17 | Status: Planning Phase

---

## 1. Current Architecture

```
Flutter App  ──→  Supabase Edge Functions (Deno/TypeScript)
                  ├── 24 functions
                  ├── _shared/ (CORS, rate limit, auth, PII mask)
                  └── PostgreSQL + Realtime + Storage

Next.js Web  ──→  Same Supabase backend (client-side calls)
```

**Edge Function inventory**: 24 functions handling AI, payments, funding, settlements, ops, identity, refunds, and scheduled tasks.

---

## 2. Why FastAPI BFF?

| Concern | Edge Functions | FastAPI BFF |
|---------|---------------|-------------|
| Cold start | ~200-500ms per invocation | Warm container (Cloud Run) |
| Rate limiting | In-function, fail-open risk (P0) | Middleware-level, circuit breaker ready |
| Request validation | Manual JSON parsing | Pydantic models, auto-validation |
| Observability | Console logs → Supabase dashboard | Structured logging, OpenTelemetry, Sentry |
| Testing | Deno test (limited tooling) | pytest, coverage, mocking |
| Deployment | Per-function `supabase functions deploy` | Docker container, Cloud Run |
| Cost | Included in Supabase plan | Cloud Run per-request pricing |
| Complexity | Simple, co-located with DB | Separate service, network hop |

---

## 3. Migration Candidates

### Phase 1: High-Priority (Sprint 1-2)

| Function | Reason | Complexity |
|----------|--------|------------|
| `payment-checkout` | P0 security (Origin validation, rate limit) | Medium |
| `payment-webhook` | HMAC validation, idempotency | Medium |
| `refund-process` | Financial atomicity | Medium |
| `ai-reply-suggest` | P0 prompt injection fix, circuit breaker | High |

### Phase 2: Medium-Priority (Sprint 3-4)

| Function | Reason | Complexity |
|----------|--------|------------|
| `payout-calculate` | Settlement logic, tax calculation | High |
| `payout-statement` | PDF generation, complex queries | Medium |
| `settlement-export` | CSV/Excel export | Low |
| `funding-pledge` | Payment integration | Medium |
| `funding-payment-webhook` | Webhook handling | Medium |

### Phase 3: Lower Priority (Sprint 5-6)

| Function | Reason | Complexity |
|----------|--------|------------|
| `ai-poll-suggest` | AI feature, similar to ai-reply | Medium |
| `verify-identity` | Third-party API integration | Medium |
| `ops-manage` | Admin operations | Low |
| `scheduled-dispatcher` | Cron jobs → Cloud Scheduler | Low |
| `campaign-complete` | Business logic | Low |
| `funding-admin-review` | Admin workflow | Low |
| `funding-studio-submit` | Studio workflow | Low |

### Keep in Edge Functions

| Function | Reason |
|----------|--------|
| `payment-confirm` | Simple status update, low latency needed |
| `payment-reconcile` | Scheduled, low frequency |
| `refresh-fallback-quotas` | Scheduled, simple |

---

## 4. Proposed FastAPI Architecture

```
Flutter App / Next.js Web
    │
    ▼
Cloud Run (FastAPI BFF)
    ├── /api/v1/checkout/          ← payment-checkout
    ├── /api/v1/webhooks/payment/  ← payment-webhook
    ├── /api/v1/ai/reply-suggest/  ← ai-reply-suggest
    ├── /api/v1/settlement/        ← payout-*
    └── /api/v1/funding/           ← funding-*
    │
    ▼
Supabase (PostgreSQL + Realtime + Storage)
```

### Tech Stack

| Component | Choice |
|-----------|--------|
| Framework | FastAPI 0.115+ |
| Runtime | Python 3.12 |
| Validation | Pydantic v2 |
| DB Client | `supabase-py` or `asyncpg` |
| HTTP Client | `httpx` (async) |
| Auth | JWT validation (supabase-py) |
| Hosting | Google Cloud Run |
| CI/CD | GitHub Actions → Cloud Build → Cloud Run |
| Monitoring | Sentry + Cloud Logging |
| Rate Limiting | `slowapi` or Redis-based |

### Key Design Decisions

1. **Pydantic models**: Mirror TypeScript types from Edge Functions
2. **Dependency injection**: FastAPI `Depends()` for auth, rate limiting, Supabase client
3. **Circuit breaker**: `pybreaker` for external API calls (TossPayments, Anthropic)
4. **Structured logging**: JSON format, correlation IDs
5. **Health check**: `/health` endpoint for Cloud Run

---

## 5. Migration Strategy

### Parallel Operation (Recommended)

```
Phase 1: Deploy FastAPI with payment endpoints
         Edge Functions remain active
         Feature flag toggles traffic

Phase 2: Validate FastAPI payment flow in staging
         Monitor error rates, latency

Phase 3: Gradually shift traffic (10% → 50% → 100%)
         Keep Edge Functions as fallback

Phase 4: Decommission migrated Edge Functions
         Update client SDKs to point to BFF
```

### Client Changes Required

| Client | Change |
|--------|--------|
| Flutter | New base URL env var (`BFF_BASE_URL`) |
| Next.js | Proxy `/api/bff/*` to Cloud Run |
| Edge Functions | Keep for non-migrated functions |

---

## 6. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Network latency (extra hop) | Medium | Cloud Run in same region as Supabase |
| Deployment complexity | Medium | Docker + Cloud Build automation |
| Cost increase | Low | Cloud Run free tier (2M requests/month) |
| Auth token forwarding | Low | Pass JWT in Authorization header |
| Data consistency | Medium | Same DB, transaction isolation |
| Team learning curve | Medium | FastAPI is well-documented, Python familiar |

---

## 7. Prerequisites

- [ ] Google Cloud project setup
- [ ] Cloud Run service account with Supabase access
- [ ] Secret Manager for API keys (TOSSPAYMENTS_SECRET_KEY, ANTHROPIC_API_KEY)
- [ ] CI/CD pipeline (GitHub Actions → Cloud Build)
- [ ] Staging environment for parallel testing
- [ ] Feature flag system (LaunchDarkly or env-based)
- [ ] Monitoring dashboard (Cloud Monitoring + Sentry)

---

## 8. Timeline Estimate

| Phase | Duration | Deliverables |
|-------|----------|-------------|
| Setup | 1 week | Cloud Run, CI/CD, base FastAPI app |
| Phase 1 | 2 weeks | Payment endpoints migrated |
| Phase 2 | 2 weeks | Settlement + AI endpoints |
| Phase 3 | 2 weeks | Funding + remaining endpoints |
| Validation | 1 week | Staging load testing, error monitoring |
| Cutover | 1 week | Production traffic shift |
| **Total** | **~9 weeks** | |

---

## 9. Decision

**Recommendation**: Proceed with FastAPI BFF migration starting with payment endpoints (Phase 1), run parallel with Edge Functions for 2-4 weeks, then gradually shift traffic.

**Key benefits**:
- Resolves P0 rate-limit fail-open issue
- Enables circuit breaker for external APIs
- Better observability and testing
- Positions for future complexity (multi-PG, A/B pricing)

**Decision status**: Pending team review
