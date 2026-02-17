/**
 * Demo Configuration
 *
 * Flutter DemoConfig 미러링.
 * 데모 모드에서 사용하는 모든 상수 및 유틸리티.
 */
export const demoConfig = {
  // ============================================================
  // 데모 사용자
  // ============================================================
  demoCreatorId: 'demo_creator_001',
  demoFanId: 'demo_user_001',
  demoCreatorName: '하늘달 (데모)',
  demoFanName: '데모 팬',

  // ============================================================
  // 데모 초기값
  // ============================================================
  initialDtBalance: 15000,
  initialStarBalance: 50,
  demoSubscriberCount: 1234,
  demoMonthlyRevenue: 1250000,

  // ============================================================
  // 아바타/배너 URL 생성기
  // ============================================================
  avatarUrl(seed: string, size = 200): string {
    return `https://picsum.photos/seed/${seed}/${size}`
  },

  bannerUrl(seed: string, width = 400, height = 200): string {
    return `https://picsum.photos/seed/${seed}/${width}/${height}`
  },

  // ============================================================
  // 데모 크리에이터 목록
  // ============================================================
  creators: [
    { id: 'demo-creator-1', name: 'WAKER', seed: 'waker' },
    { id: 'demo-creator-2', name: 'MOONLIGHT', seed: 'moonlight' },
    { id: 'demo-creator-3', name: 'STARLIGHT', seed: 'starlight' },
  ] as const,
} as const
