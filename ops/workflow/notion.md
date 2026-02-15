# Notion 구조 (고정)

## Databases / Data Sources

| DB 이름 | 용도 |
|---------|------|
| Work Items | WI 추적 (1 WI = 1 Slack 스레드 = 1 PR) |
| Decision Log | 주요 결정 기록 (아키텍처, 정책, 기술 선택) |
| Incidents | 인시던트 기록 및 사후 분석 |

## Work Items 속성

| 속성 | 타입 | 설명 |
|------|------|------|
| Title | title | WI 제목 |
| WI-ID | rich_text | 고유 식별자 (예: WI-001) |
| Status | select | Intake / Routed / Gates Pending / Blocked / Builder Working / Review / Ready to Ship / Done / Archived |
| Priority | select | P0 / P1 / P2 / P3 |
| Owner | people | 담당자 |
| Gate:Security | checkbox | 보안 게이트 완료 |
| Gate:UIUX | checkbox | UIUX 게이트 완료 |
| Gate:Legal | checkbox | 법무 게이트 완료 |
| Gate:Tax | checkbox | 세무 게이트 완료 |
| Slack Thread | url | Slack 스레드 링크 |
| PR | url | Pull Request 링크 |
| Release | url | 배포 링크 |
| Risk | select | P0 / P1 / P2 / P3 |

> **API 참고**: Notion API에서 `status` 타입 속성 생성이 막힐 수 있으므로 `select`로 생성한다.

## WI Template (Seed) 구조

```markdown
# [WI 제목]

## 배경 / 목표
- 왜 이 작업이 필요한가?
- 달성하려는 결과는?

## 범위
- 포함: ...
- 제외: ...

## 리스크
- ...

## Gate 산출물
### Security/DB
- (산출물 여기에)

### UIUX/Observability
- (산출물 여기에)

### Legal
- (산출물 여기에)

### Tax/Accounting
- (산출물 여기에)

## 구현 / 검증
- Builder Plan: ...
- /qa 결과: ...
- /verify 결과: ...

## 릴리즈 / 공지
- PR: ...
- Deploy: ...
- Release Notes: ...

## 결정 로그
| 날짜 | 결정 | 사유 | 결정자 |
|------|------|------|--------|
| | | | |
```

## DB Template 수동 설정 (1회)

> Notion API로는 DB Template을 직접 만들 수 없습니다. 아래 클릭 경로를 따라 수동 설정하세요.

### 클릭 경로
1. Work Items DB 열기
2. 우측 상단 `...` → `Templates` (또는 `새로 만들기` 옆 `▼`)
3. `+ New template` 클릭
4. "WI Template (Seed)" 페이지를 선택하거나 내용 복사
5. `Set as default` 체크
6. 저장

이 설정을 하면 Work Items에서 `+ New` 클릭 시 자동으로 템플릿이 적용됩니다.
