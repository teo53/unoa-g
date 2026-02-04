# UNO A Web Application

Next.js 15 기반의 UNO A 웹 애플리케이션입니다. 크리에이터 펀딩 플랫폼의 공개 페이지, 크리에이터 스튜디오, 관리자 패널을 제공합니다.

## 기능

### 공개 페이지 (SEO 최적화)
- `/funding` - 펀딩 캠페인 목록
- `/p/[slug]` - 캠페인 상세 페이지 (OG 이미지, JSON-LD)
- `/p/[slug]/prelaunch` - 사전 알림 신청

### 크리에이터 스튜디오
- `/studio` - 대시보드
- `/studio/campaigns/new` - 캠페인 생성
- `/studio/campaigns/[id]/edit` - 캠페인 수정 (Tiptap 에디터)
- `/studio/campaigns/[id]/preview` - 미리보기
- `/studio/campaigns/[id]/submit` - 심사 제출

### 관리자 패널
- `/admin` - 심사 대기 목록
- `/admin/campaigns/[id]` - 캠페인 심사
- `/admin/reports` - 신고 관리

## 시작하기

### 1. 환경 설정

```bash
# 환경 변수 파일 생성
cp .env.example .env.local
```

`.env.local` 파일을 열고 Supabase 정보를 입력합니다:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 2. 의존성 설치

```bash
npm install
```

### 3. 개발 서버 실행

```bash
npm run dev
```

[http://localhost:3000](http://localhost:3000)에서 확인할 수 있습니다.

## 기술 스택

- **Framework**: Next.js 15 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Auth & Database**: Supabase
- **Editor**: Tiptap (Block Editor)
- **Drag & Drop**: dnd-kit
- **Icons**: Lucide React

## 프로젝트 구조

```
apps/web/
├── app/
│   ├── (public)/          # 공개 라우트
│   │   ├── funding/       # 펀딩 목록
│   │   └── p/[slug]/      # 캠페인 상세
│   ├── (studio)/          # 크리에이터 스튜디오
│   │   └── studio/
│   ├── (admin)/           # 관리자 패널
│   │   └── admin/
│   ├── api/               # API 라우트
│   ├── layout.tsx         # 루트 레이아웃
│   └── page.tsx           # 랜딩 페이지
├── components/
│   ├── ui/                # 공통 UI 컴포넌트
│   ├── campaign/          # 캠페인 컴포넌트
│   ├── studio/            # 스튜디오 컴포넌트
│   └── admin/             # 관리자 컴포넌트
├── lib/
│   ├── supabase/          # Supabase 클라이언트
│   ├── types/             # TypeScript 타입
│   └── utils/             # 유틸리티 함수
└── middleware.ts          # Auth 미들웨어
```

## Supabase 설정

### 마이그레이션 적용

```bash
cd ../../supabase
supabase db push
```

### Edge Functions 배포

```bash
supabase functions deploy funding-pledge
supabase functions deploy funding-admin-review
supabase functions deploy funding-studio-submit
```

### Storage 버킷 생성

Supabase 대시보드에서 다음 버킷을 생성합니다:

1. **campaign-images** (Public)
   - 파일 크기 제한: 10MB
   - 허용 MIME: image/jpeg, image/png, image/webp, image/gif

2. **campaign-files** (Private)
   - 파일 크기 제한: 50MB
   - 허용 MIME: application/pdf, video/*

## 배포

### Vercel 배포

```bash
npm run build
```

환경 변수를 Vercel 프로젝트 설정에 추가합니다.

## 개발 명령어

```bash
npm run dev          # 개발 서버 실행
npm run build        # 프로덕션 빌드
npm run start        # 프로덕션 서버 실행
npm run lint         # ESLint 실행
npm run type-check   # TypeScript 타입 체크
```

## 관련 문서

- [Next.js 문서](https://nextjs.org/docs)
- [Supabase 문서](https://supabase.com/docs)
- [Tiptap 문서](https://tiptap.dev/)
- [Tailwind CSS 문서](https://tailwindcss.com/docs)
