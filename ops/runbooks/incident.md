# Incident Runbook

## 0. 온콜 역할 (Roles)

| 역할 | 책임 | P0 | P1-P2 |
|------|------|:---:|:-----:|
| **IC** (총괄) | 인시던트 소유, 의사결정, 전체 조율 | 필수 | 필수 |
| **Ops** (조치) | 기술적 완화/롤백/복구 실행 | 필수 | 필수 |
| **Comms** (공지) | Slack 스레드 업데이트, 이해관계자 알림, 외부 공지 | 필수 | 선택 |
| **Scribe** (기록) | 타임라인 기록, Notion 포스트모템 작성, 런북 업데이트 | 필수 | 선택 |

> P0 인시던트에서는 4개 역할 모두 배정 필수.
> P1-P2에서는 IC와 Ops가 Comms/Scribe를 겸임 가능.

---

## 1. 선언 (Declare)
- Slack `#ops-incidents`에 단일 스레드로 선언
- WI 링크가 있으면 포함
- 형식: `[SEV-P?] <제목> | 시작: <시간> | 영향: <범위>`

## 2. 분류 (Classify)

| 등급 | 기준 | 대응 |
|------|------|------|
| P0 | 전체 서비스 중단 / 결제 장애 / 데이터 유출 | 즉시 대응, 15분 업데이트 |
| P1 | 핵심 기능 부분 장애 | 1시간 내 대응, 30분 업데이트 |
| P2 | 비핵심 기능 장애 | 4시간 내 대응 |
| P3 | 사소한 이슈 | 다음 스프린트 대응 |

## 3. 완화 (Mitigate)
```
Stop-the-bleed 우선순위:
1. Feature flag OFF / Kill switch
2. 이전 버전 롤백 (git revert + deploy)
3. DB 변경 롤백 (migration down)
4. 서비스 격리 (Edge Function 비활성화)
```

## 4. 소통 (Communicate)
- P0/P1: Slack 스레드에 15분마다 업데이트
- 내부 이해관계자 알림
- 사용자 영향 시 공지 준비

## 5. 근본 원인 (Root Cause)
```
타임라인 → 트리거 → 기여 요인 → 영향 범위
```

## 6. 방지 (Prevent)
- 가드레일 추가 (테스트, 알림, 런북)
- 관련 Gate 산출물 업데이트

## 7. 종결 (Close)
- Notion Incident 페이지 작성
- 링크 정리: PR, deploy, Slack thread
- 런북 업데이트 여부 확인
