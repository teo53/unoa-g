# Edge Function 배포/롤백 런북

## 1. 함수 목록 (Function Registry)

### 결제/정산
| 함수 | 필수 환경변수 |
|------|-------------|
| `payment-checkout` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `TOSSPAYMENTS_SECRET_KEY` |
| `payment-confirm` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `TOSSPAYMENTS_SECRET_KEY` |
| `payment-webhook` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `TOSSPAYMENTS_SECRET_KEY` |
| `payment-reconcile` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `TOSSPAYMENTS_SECRET_KEY` |
| `refund-process` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `TOSSPAYMENTS_SECRET_KEY` |

### 펀딩
| 함수 | 필수 환경변수 |
|------|-------------|
| `funding-pledge` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `funding-payment-webhook` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `TOSSPAYMENTS_SECRET_KEY` |
| `funding-admin-review` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `funding-studio-submit` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `campaign-complete` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |

### 정산
| 함수 | 필수 환경변수 |
|------|-------------|
| `payout-calculate` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `payout-statement` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `settlement-export` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |

### AI
| 함수 | 필수 환경변수 |
|------|-------------|
| `ai-reply-suggest` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY` |
| `ai-poll-suggest` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY` |

### 운영/기타
| 함수 | 필수 환경변수 |
|------|-------------|
| `ops-manage` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `agency-manage` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `agency-settlement-calculate` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `verify-identity` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `subscription-pricing` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `scheduled-dispatcher` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `CRON_SECRET` |
| `refresh-fallback-quotas` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `CRON_SECRET` |

---

## 2. 배포 명령어 (Deploy Commands)

### 단일 함수 배포
```bash
supabase functions deploy <function-name> --project-ref <ref>
```

### 전체 배포
```bash
supabase functions deploy --project-ref <ref>
```

### 환경변수 설정
```bash
# 개별 설정
supabase secrets set ANTHROPIC_API_KEY=<value> --project-ref <ref>

# 파일에서 일괄 설정
supabase secrets set --env-file .env.edge --project-ref <ref>

# 현재 설정 확인
supabase secrets list --project-ref <ref>
```

---

## 3. 배포 검증 (Verify Deployment)

1. **대시보드 확인**: Supabase Dashboard → Edge Functions → 함수명 → Deployments 탭에서 최신 배포 시각 확인
2. **헬스 체크 (curl)**:
   ```bash
   # 인증이 필요 없는 함수 (CORS preflight)
   curl -i -X OPTIONS \
     https://<PROJECT_REF>.supabase.co/functions/v1/<function-name>

   # 인증이 필요한 함수 (실제 호출)
   curl -i -X POST \
     https://<PROJECT_REF>.supabase.co/functions/v1/<function-name> \
     -H "Authorization: Bearer <SUPABASE_ANON_KEY>" \
     -H "Content-Type: application/json" \
     -d '{}'
   ```
3. **로그 확인**: Dashboard → Edge Functions → 함수명 → Logs에서 최신 요청 확인

---

## 4. 롤백 (Rollback)

### 이전 버전으로 롤백
```bash
supabase functions deploy <function-name> --version <previous-version> --project-ref <ref>
```

> 버전 ID는 Dashboard → Edge Functions → 함수명 → Deployments 탭에서 확인 가능.

### 긴급 비활성화 (함수 단위)
함수 자체를 비활성화하는 CLI 명령은 없음. 대안:
- **CORS만 응답하는 스텁으로 배포** (가장 빠른 차단)
- **관련 pg_cron 잡 비활성화** (크론 함수인 경우):
  ```sql
  UPDATE cron.job SET active = false WHERE command LIKE '%<function-name>%';
  ```

---

## 5. 장애 증상 & 트리아지 (Failure Symptoms)

| 증상 | 가능한 원인 | 확인 방법 |
|------|-----------|----------|
| 콜드 스타트 > 10초 | 함수 번들 크기 과대 / esm.sh 외부 의존성 지연 | Dashboard → 함수 → Logs에서 첫 응답 시간 확인 |
| 모든 요청 500 | 환경변수 누락 / import_map.json 오류 / 런타임 에러 | `supabase secrets list`로 환경변수 확인 + 로그 확인 |
| 인증 에러 (401/403) | `SUPABASE_SERVICE_ROLE_KEY` 미전파 / CRON_SECRET 불일치 | 환경변수 재설정 후 재배포 없이 즉시 반영 |
| CORS 에러 (브라우저) | `_shared/cors.ts` 허용 도메인 목록 미포함 | cors.ts의 allowedOrigins 배열 확인 |
| 배포 실패 | Deno 문법 에러 / import URL 404 | 로컬 `deno check` 실행으로 사전 검증 |

---

## 6. 안전한 배포 순서 (Safe Deploy Order)

권장: 결제/인증 관련 함수는 **스테이징 먼저 배포 후 검증**.

```
1. 스테이징 프로젝트에 배포 + 환경변수 동기화
2. 스테이징에서 curl 테스트 (§3)
3. 프로덕션에 배포
4. 프로덕션 로그 5분 관찰
5. 이상 시 즉시 롤백 (§4)
```

> 결제 함수(`payment-*`)는 반드시 스테이징 검증 후 프로덕션 배포.
