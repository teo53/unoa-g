# 관측성 일일 점검 런북

> 대상: 운영 담당자 (비개발자 OK) | 도구: Supabase Dashboard > SQL Editor
> 마이그레이션: `073_observability_tables.sql` | 정의서: `docs/audit/observability-triggers.md`

---

## 1. 매일 점검 루틴 (10:00 KST)

아래 4개 쿼리를 순서대로 SQL Editor에 붙여넣고 실행합니다.

### 1-1. Cron 작업 실패 확인 (T1)

```sql
SELECT jobid, status, COUNT(*) AS runs,
  AVG(EXTRACT(EPOCH FROM (end_time - start_time))) AS avg_seconds
FROM cron.job_run_details
WHERE start_time >= now() - INTERVAL '24 hours'
GROUP BY jobid, status
ORDER BY jobid, status;
```

**확인 사항**: `status = 'failed'` 행이 있으면 아래 상세 조회:

```sql
SELECT jobid, status, return_message, start_time
FROM cron.job_run_details
WHERE start_time >= now() - INTERVAL '24 hours'
  AND status <> 'succeeded'
ORDER BY start_time DESC LIMIT 20;
```

### 1-2. 실행 중 작업 + 24h 이력 (T3)

```sql
-- 현재 실행 중 (비어있어야 정상)
SELECT job_name, job_type, started_at,
  EXTRACT(EPOCH FROM (now() - started_at))::INT AS seconds_running
FROM ops_jobs WHERE status = 'running'
ORDER BY started_at ASC;

-- 24h 이력 요약
SELECT job_name, COUNT(*) AS runs,
  AVG(duration_ms)/1000 AS avg_sec,
  MAX(duration_ms)/1000 AS max_sec,
  COUNT(*) FILTER (WHERE status = 'failed') AS failures
FROM ops_jobs
WHERE started_at > now() - INTERVAL '24 hours'
GROUP BY job_name ORDER BY avg_sec DESC;
```

### 1-3. 미들웨어 이벤트 알람 (T4)

```sql
SELECT fn_name, event_type, COUNT(*) AS cnt
FROM ops_mw_events
WHERE recorded_at > now() - INTERVAL '1 hour'
GROUP BY fn_name, event_type
HAVING
  (event_type = 'rate_limited'    AND COUNT(*) > 100)
  OR (event_type = 'schema_invalid' AND COUNT(*) > 50)
  OR (event_type = 'circuit_open'   AND COUNT(*) > 0)
  OR (event_type = 'abuse_suspected' AND COUNT(*) > 10)
  OR (event_type = 'slow_request'   AND COUNT(*) > 20)
ORDER BY cnt DESC;
```

**행이 1개라도 나오면** → 아래 인시던트 등록 절차 진행.

### 1-4. 열린 인시던트 확인 (T2)

```sql
SELECT id, title, severity, status, open_at,
  EXTRACT(EPOCH FROM (now() - open_at))::INT / 60 AS minutes_open,
  slack_thread
FROM ops_incidents
WHERE status <> 'closed'
ORDER BY severity ASC, open_at ASC;
```

**P0이 90분 이상 열려 있으면** → Slack `#ops-incidents` 에스컬레이션.

---

## 2. 인시던트 등록/종료

### 인시던트 열기

```sql
INSERT INTO ops_incidents (title, severity, trigger_type, affected_fn, slack_thread, notion_wi)
VALUES (
  '간단한 제목',         -- 예: 'payment-checkout 5xx 연속'
  'P1',                  -- P0/P1/P2/P3
  'alert',               -- manual/alert/pg_cron/edge_fn
  'payment-checkout',    -- 영향 함수 (없으면 NULL)
  'https://slack.com/archives/C.../p...', -- Slack 스레드 URL
  'WI-OBS-xxx'           -- Notion WI 번호
);
```

### 완화 단계로 전환

```sql
UPDATE ops_incidents
SET status = 'mitigating', mitigated_at = now()
WHERE title = '간단한 제목' AND status = 'open';
```

### 인시던트 종료

```sql
UPDATE ops_incidents
SET status = 'closed', closed_at = now(),
    notes = '원인: ... / 조치: ...'
WHERE title = '간단한 제목' AND status IN ('open', 'mitigating', 'monitoring');
```

> `mttr_minutes`는 자동 계산됩니다 (`closed_at - open_at`).

---

## 3. 알람 임계값 기준

| ID | 조건 | 등급 |
|----|------|------|
| T1-AL2 | cron 같은 jobid 연속 3회 실패 | **P0** |
| T1-AL5 | payment-* 함수 5xx 연속 | **P0** |
| T4-AL3 | `circuit_open` 이벤트 1건 이상 | **P1** |
| T4-AL4 | `abuse_suspected` > 10/시간 | **P1** |
| T2-AL1 | P0 인시던트 90분 이상 미해결 | **P0 에스컬레이션** |

### 오발령 처리
1. 임계값이 2주 내 3회 이상 오발령 → Notion WI 생성하여 조정
2. 기준선 수집 기간 (배포 후 2주)에는 알람만 기록, 에스컬레이션은 보류
3. 전체 임계값 목록: `docs/audit/observability-triggers.md` 참조

---

## 4. FastAPI 전환 시 체크리스트

- [ ] `ops_mw_events` INSERT를 FastAPI 미들웨어에서 직접 실행하도록 변경
- [ ] Edge Function `emitMwEvent` 호출 제거 (FastAPI가 대체)
- [ ] `ops_jobs` INSERT를 FastAPI background task에서 실행
- [ ] Grafana/Datadog 연동 시 이 런북의 SQL 쿼리를 대시보드로 이전
- [ ] pg_cron cleanup 작업은 유지 (DB 레벨이므로 FastAPI 무관)

---

## 5. 관련 문서

| 문서 | 경로 |
|------|------|
| 인시던트 런북 | `ops/runbooks/incident.md` |
| 결제 모니터링 | `ops/runbooks/payments.md` |
| Cron 작업 런북 | `ops/runbooks/cron.md` |
| Edge Function 런북 | `ops/runbooks/edge-functions.md` |
| T1-T4 지표 정의서 | `docs/audit/observability-triggers.md` |
| 마이그레이션 스키마 | `supabase/migrations/073_observability_tables.sql` |
| 이벤트 이미터 모듈 | `supabase/functions/_shared/mw_metrics.ts` |
