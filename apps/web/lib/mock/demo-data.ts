// Demo mock data for explicit demo deployments
// SECURITY: demo mode must be explicitly enabled via environment variable.

import {
  CampaignEnhanced,
  RewardTierEnhanced,
  FaqItem,
  CampaignUpdate_,
  CampaignComment,
  CampaignReview,
  PlatformPolicy,
  GalleryImage,
  EventSchedule,
  BudgetInfo,
  TeamInfo,
  StretchGoal,
  Benefit,
  Notice,
  ScheduleMilestone,
  UserProfile,
} from '../types/database'

export const DEMO_MODE =
  process.env.NEXT_PUBLIC_DEMO_MODE === 'true' ||
  process.env.NEXT_PUBLIC_DEMO_BUILD === 'true'

// ============================================
// Demo Creators
// ============================================
export const mockCreators: Record<string, UserProfile> = {
  'demo-creator-1': {
    id: 'demo-creator-1',
    role: 'creator',
    display_name: 'WAKER',
    avatar_url: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',
    bio: '6인조 보이그룹 WAKER입니다. 2023년 데뷔.',
    created_at: '2023-01-01T00:00:00Z',
    updated_at: '2025-01-01T00:00:00Z',
  },
  'demo-creator-2': {
    id: 'demo-creator-2',
    role: 'creator',
    display_name: 'MOONLIGHT',
    avatar_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
    bio: '독립 아티스트 MOONLIGHT입니다.',
    created_at: '2022-06-01T00:00:00Z',
    updated_at: '2025-01-01T00:00:00Z',
  },
  'demo-creator-3': {
    id: 'demo-creator-3',
    role: 'creator',
    display_name: 'STARLIGHT',
    avatar_url: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop',
    bio: '솔로 아티스트 STARLIGHT입니다.',
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2025-01-01T00:00:00Z',
  },
}

// ============================================
// Enhanced Campaigns (Makestar/Tumblbug Style)
// ============================================
export const mockCampaigns: CampaignEnhanced[] = [
  {
    // Basic Info
    id: '1',
    creator_id: 'demo-creator-1',
    slug: 'waker-3rd-album-fansign',
    title: 'WAKER 3rd Mini Album [In Elixir: Spellbound] MEET&CALL EVENT',
    subtitle: 'HAPPY KWONHYEOP DAY 기념 팬사인회 & 영상통화 이벤트',
    cover_image_url: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=600&fit=crop',
    category: 'K-POP',
    status: 'active',

    // Funding
    goal_amount_dt: 500000,
    current_amount_dt: 387500,
    backer_count: 156,

    // Dates
    start_at: '2026-02-03T15:00:00Z',
    end_at: '2026-02-05T23:59:59Z',

    // Content
    description_md: null,
    description_html: `
      <h1>WAKER 3rd Mini Album 펀딩</h1>
      <p>안녕하세요, WAKER입니다! 🎵</p>
      <p>권협 생일을 기념하여 특별한 팬사인회 & 영상통화 이벤트를 준비했습니다.</p>
      <h2>앨범 소개</h2>
      <p>3rd Mini Album [In Elixir: Spellbound]는 마법과 신비로운 세계관을 담은 앨범입니다.</p>
      <h2>타이틀곡</h2>
      <p>"Spellbound"는 강렬한 비트와 몽환적인 멜로디가 조화를 이루는 곡입니다.</p>
      <img src="https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800" alt="앨범 컨셉" />
      <h2>앨범 구성</h2>
      <ul>
        <li>CD + 포토북 (80P)</li>
        <li>포토카드 랜덤 2종</li>
        <li>접지 포스터 1종</li>
        <li>스티커팩</li>
      </ul>
    `,

    // Gallery Images (Tumblbug style)
    gallery_images: [
      { url: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800', caption: '메인 이미지', display_order: 0 },
      { url: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800', caption: '앨범 컨셉', display_order: 1 },
      { url: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800', caption: '포토카드 미리보기', display_order: 2 },
      { url: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=800', caption: '팬사인회 이미지', display_order: 3 },
    ],

    // Event Schedule (Makestar style)
    event_schedule: {
      sale_period: { start: '2026-02-03', end: '2026-02-05' },
      winner_announce: '2026-02-06 14:00 (KST)',
      fansign_date: '2026-02-10 19:30 (KST)',
      videocall_date: '2026-02-10 (1부 종료 후)',
      shipping_date: '2026-02-20 이후 순차 발송',
      custom_events: [
        { label: '응모 마감', date: '2026-02-05 23:59', description: '기한 내 결제 완료 필수' },
      ],
    },

    // Related Products
    related_campaign_ids: ['2', '3'],

    // Budget Info (Tumblbug style)
    budget_info: {
      items: [
        { name: '앨범 제작비', amount: 250000, percentage: 50, description: 'CD 프레싱, 포토북 인쇄' },
        { name: '이벤트 운영비', amount: 150000, percentage: 30, description: '장소 대여, 스태프 인건비' },
        { name: '특전 제작비', amount: 75000, percentage: 15, description: '포토카드, 포스터 등' },
        { name: '배송비', amount: 25000, percentage: 5, description: '국내/해외 배송' },
      ],
      total: 500000,
      currency: 'KRW',
    },

    // Schedule Info (Tumblbug style)
    schedule_info: [
      { date: '2026-02-03', milestone: '펀딩 시작', description: '오후 3시 오픈', is_completed: true },
      { date: '2026-02-05', milestone: '펀딩 마감', description: '오후 11:59 마감', is_completed: false },
      { date: '2026-02-06', milestone: '당첨자 발표', description: '오후 2시 발표', is_completed: false },
      { date: '2026-02-10', milestone: '팬사인회 & 영상통화', description: '저녁 7:30 시작', is_completed: false },
      { date: '2026-02-20', milestone: '리워드 발송 시작', description: '순차 발송', is_completed: false },
    ],

    // Team Info (Tumblbug style)
    team_info: {
      company_name: 'WAKER Entertainment',
      company_description: '아티스트 WAKER의 공식 매니지먼트',
      members: [
        { name: '권협', role: '리더, 메인보컬', avatar_url: 'https://i.pravatar.cc/150?u=kwon', bio: '1999년생, 팀 내 막내' },
        { name: '준서', role: '메인댄서', avatar_url: 'https://i.pravatar.cc/150?u=jun', bio: '1997년생' },
        { name: '민재', role: '래퍼', avatar_url: 'https://i.pravatar.cc/150?u=min', bio: '1998년생' },
        { name: '도윤', role: '서브보컬', avatar_url: 'https://i.pravatar.cc/150?u=do', bio: '1997년생' },
        { name: '시우', role: '비주얼', avatar_url: 'https://i.pravatar.cc/150?u=si', bio: '1998년생' },
        { name: '하준', role: '막내, 서브래퍼', avatar_url: 'https://i.pravatar.cc/150?u=ha', bio: '2000년생' },
      ],
    },

    // Stretch Goals (Tumblbug style)
    stretch_goals: [
      { amount_dt: 300000, title: '포토카드 추가 2종', description: '랜덤 포토카드 2종 추가 증정', is_reached: true, reached_at: '2026-02-04T10:30:00Z' },
      { amount_dt: 400000, title: '스페셜 포스터', description: '단체 스페셜 포스터 추가 증정', is_reached: false },
      { amount_dt: 500000, title: '미공개 포토북', description: '비하인드 포토북 8P 추가', is_reached: false },
    ],

    // Benefits/Perks (Makestar style)
    benefits: [
      {
        title: '미공개 셀카 포토카드 1매',
        description: '앨범 1장당 1장 랜덤 증정, 6종 중 랜덤 1종\n* 한 주문 건에서 앨범 6매 구매 시 포토카드 중복 없이 증정',
        images: [
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
        ],
        for_type: 'all',
      },
      {
        title: '대면 팬사인회 참석권',
        description: '1) 대면 팬사인회 참석권\n2) 기명 사인 앨범 1매 (구매하신 앨범 중 1매)\n3) 권협 생일 포토카드 1매',
        for_type: 'fansign',
      },
      {
        title: '영상통화 이벤트 참여권',
        description: '1인당 약 1분 30초 영상통화\n* 통화 시간은 참여 인원에 따라 변동될 수 있습니다',
        for_type: 'videocall',
      },
    ],

    // Enabled Tabs
    enabled_tabs: ['intro', 'rewards', 'updates', 'faq', 'community', 'reviews'],

    // Notices (Makestar style)
    notices: [
      {
        title: '이벤트 응모자 정보 입력 유의사항',
        content_html: '<p>정확한 연락처 정보를 입력해주세요. 당첨 시 안내 문자가 발송됩니다.</p><p>허위 정보 입력 시 당첨이 취소될 수 있습니다.</p>',
        display_order: 0,
      },
      {
        title: '영상통화 이벤트 진행 관련 유의사항',
        content_html: '<p>안정적인 네트워크 환경에서 참여해주세요.</p><p>통화 중 녹화/녹음은 금지됩니다.</p><p>부적절한 행동 시 강제 종료될 수 있습니다.</p>',
        display_order: 1,
      },
      {
        title: '대면 팬사인회 참여 유의사항',
        content_html: '<p>본인 확인을 위해 신분증을 지참해주세요.</p><p>현장에서 사진 촬영은 금지됩니다.</p>',
        display_order: 2,
      },
    ],

    // Metadata
    rejection_reason: null,
    reviewed_by: null,
    reviewed_at: null,
    created_at: '2026-01-25T00:00:00Z',
    updated_at: '2026-02-03T15:00:00Z',
    submitted_at: '2026-01-28T00:00:00Z',
    approved_at: '2026-02-01T00:00:00Z',
    completed_at: null,

    // Joined data
    creator: mockCreators['demo-creator-1'],
  },

  // Campaign 2 - MOONLIGHT Concert
  {
    id: '2',
    creator_id: 'demo-creator-2',
    slug: 'moonlight-concert-2026',
    title: 'MOONLIGHT 단독 콘서트 "Under the Moon"',
    subtitle: '팬들과 함께 만드는 첫 번째 단독 콘서트',
    cover_image_url: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=800&h=600&fit=crop',
    category: 'concert',
    status: 'active',

    goal_amount_dt: 1000000,
    current_amount_dt: 780000,
    backer_count: 312,

    start_at: '2026-01-20T00:00:00Z',
    end_at: '2026-02-28T23:59:59Z',

    description_md: null,
    description_html: `
      <h1>MOONLIGHT 단독 콘서트</h1>
      <p>달빛 아래에서 여러분과 함께하고 싶습니다 🌙</p>
      <h2>공연 정보</h2>
      <ul>
        <li>일시: 2026년 4월 중</li>
        <li>장소: 서울 (후원 달성 시 확정)</li>
        <li>규모: 약 500석</li>
      </ul>
    `,

    gallery_images: [
      { url: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=800', caption: '콘서트 이미지', display_order: 0 },
      { url: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800', caption: '무대 컨셉', display_order: 1 },
    ],

    event_schedule: {
      sale_period: { start: '2026-01-20', end: '2026-02-28' },
      custom_events: [
        { label: '공연 일정 확정', date: '2026-03-15', description: '펀딩 성공 시' },
        { label: '티켓 발송', date: '2026-03-20', description: '당첨자 대상' },
      ],
    },

    related_campaign_ids: ['1'],

    budget_info: {
      items: [
        { name: '공연장 대여', amount: 400000, percentage: 40 },
        { name: '무대/음향 설치', amount: 300000, percentage: 30 },
        { name: '스태프 인건비', amount: 200000, percentage: 20 },
        { name: '굿즈 제작', amount: 100000, percentage: 10 },
      ],
      total: 1000000,
      currency: 'KRW',
    },

    schedule_info: [
      { date: '2026-01-20', milestone: '펀딩 시작', is_completed: true },
      { date: '2026-02-28', milestone: '펀딩 마감', is_completed: false },
      { date: '2026-03-15', milestone: '공연장 확정', is_completed: false },
      { date: '2026-04-15', milestone: '콘서트 개최 (예정)', is_completed: false },
    ],

    team_info: {
      members: [
        { name: 'MOONLIGHT', role: '아티스트', avatar_url: 'https://i.pravatar.cc/150?u=moon', bio: '독립 싱어송라이터' },
        { name: '김지훈', role: '매니저', avatar_url: 'https://i.pravatar.cc/150?u=kim', bio: '공연 기획 담당' },
      ],
    },

    stretch_goals: [
      { amount_dt: 700000, title: 'VIP 좌석 추가', description: '무대 앞 50석 추가', is_reached: true },
      { amount_dt: 900000, title: '포토타임 추가', description: '공연 후 단체 포토타임', is_reached: false },
      { amount_dt: 1200000, title: '앵콜 굿즈', description: '현장 판매 한정 굿즈', is_reached: false },
    ],

    benefits: [
      {
        title: '공연 포스터 (사인본)',
        description: '직접 사인한 공연 포스터 증정',
        for_type: 'all',
      },
    ],

    enabled_tabs: ['intro', 'rewards', 'updates', 'faq', 'community'],

    notices: [
      {
        title: '공연 취소/환불 안내',
        content_html: '<p>펀딩 미달성 시 전액 환불됩니다.</p>',
        display_order: 0,
      },
    ],

    rejection_reason: null,
    reviewed_by: null,
    reviewed_at: null,
    created_at: '2026-01-15T00:00:00Z',
    updated_at: '2026-01-20T00:00:00Z',
    submitted_at: null,
    approved_at: null,
    completed_at: null,

    creator: mockCreators['demo-creator-2'],
  },

  // Campaign 3 - STARLIGHT Photobook
  {
    id: '3',
    creator_id: 'demo-creator-3',
    slug: 'starlight-photobook-2026',
    title: 'STARLIGHT 첫 번째 공식 화보집 "Shine"',
    subtitle: '4가지 컨셉으로 담아낸 특별한 순간들',
    cover_image_url: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&h=600&fit=crop',
    category: 'goods',
    status: 'completed',

    goal_amount_dt: 300000,
    current_amount_dt: 450000,
    backer_count: 189,

    start_at: '2026-01-05T00:00:00Z',
    end_at: '2026-02-05T23:59:59Z',

    description_md: null,
    description_html: `
      <h1>STARLIGHT 첫 화보집 ✨</h1>
      <p>드디어 첫 공식 화보집을 제작합니다!</p>
      <h2>화보집 구성</h2>
      <ul>
        <li>총 80페이지</li>
        <li>4가지 컨셉 촬영</li>
        <li>미공개 셀카 수록</li>
        <li>직접 쓴 손편지 (인쇄)</li>
      </ul>
    `,

    gallery_images: [
      { url: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800', caption: '화보 미리보기', display_order: 0 },
    ],

    event_schedule: {
      sale_period: { start: '2026-01-05', end: '2026-02-05' },
      shipping_date: '2026-03-01 이후',
    },

    related_campaign_ids: [],

    budget_info: {
      items: [
        { name: '촬영비', amount: 150000, percentage: 50 },
        { name: '인쇄비', amount: 100000, percentage: 33 },
        { name: '배송비', amount: 50000, percentage: 17 },
      ],
      total: 300000,
      currency: 'KRW',
    },

    schedule_info: [
      { date: '2026-01-05', milestone: '펀딩 시작', is_completed: true },
      { date: '2026-02-05', milestone: '펀딩 종료', is_completed: true },
      { date: '2026-02-20', milestone: '화보집 인쇄', is_completed: false },
      { date: '2026-03-01', milestone: '발송 시작', is_completed: false },
    ],

    team_info: {
      members: [
        { name: 'STARLIGHT', role: '아티스트', avatar_url: 'https://i.pravatar.cc/150?u=star', bio: '솔로 아티스트' },
      ],
    },

    stretch_goals: [
      { amount_dt: 350000, title: '포토카드 3종 추가', is_reached: true, reached_at: '2026-01-20T00:00:00Z' },
      { amount_dt: 400000, title: '북마크 세트', is_reached: true, reached_at: '2026-01-28T00:00:00Z' },
      { amount_dt: 500000, title: '스페셜 포스터', is_reached: false },
    ],

    benefits: [],

    enabled_tabs: ['intro', 'rewards', 'updates', 'faq', 'reviews'],

    notices: [],

    rejection_reason: null,
    reviewed_by: null,
    reviewed_at: null,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-02-05T23:59:59Z',
    submitted_at: null,
    approved_at: null,
    completed_at: '2026-02-05T23:59:59Z',

    creator: mockCreators['demo-creator-3'],
  },
]

// ============================================
// Enhanced Reward Tiers (Makestar Style)
// ============================================
export const mockTiers: RewardTierEnhanced[] = [
  // Campaign 1 Tiers
  {
    id: 't1',
    campaign_id: '1',
    title: '앨범 응원팩',
    description: '앨범 1장 + 미공개 셀카 포토카드 1매 (랜덤)',
    price_dt: 200,
    total_quantity: null,
    remaining_quantity: null,
    display_order: 0,
    is_active: true,
    is_featured: false,
    pledge_count: 89,
    estimated_delivery_at: '2026-02-20T00:00:00Z',
    created_at: '2026-01-25T00:00:00Z',
    updated_at: '2026-01-25T00:00:00Z',

    badge_type: null,
    badge_label: undefined,
    member_options: [],
    has_member_selection: false,
    included_items: [
      { name: '정규 앨범', quantity: 1, description: 'CD + 포토북' },
      { name: '미공개 셀카 포토카드', quantity: 1, description: '6종 중 랜덤' },
    ],
    shipping_info: '국내 무료 배송 / 해외 배송비 별도',
    images: [],
  },
  {
    id: 't2',
    campaign_id: '1',
    title: '팬사인회 응모권',
    description: '앨범 1장 + 대면 팬사인회 응모권 1매 (멤버 선택 가능)',
    price_dt: 500,
    total_quantity: 100,
    remaining_quantity: 23,
    display_order: 1,
    is_active: true,
    is_featured: true,
    pledge_count: 77,
    estimated_delivery_at: '2026-02-10T00:00:00Z',
    created_at: '2026-01-25T00:00:00Z',
    updated_at: '2026-01-25T00:00:00Z',

    badge_type: 'recommended',
    badge_label: '추천',
    member_options: [
      { member_name: '권협', member_id: 'kwon', avatar_url: 'https://i.pravatar.cc/150?u=kwon' },
      { member_name: '준서', member_id: 'jun', avatar_url: 'https://i.pravatar.cc/150?u=jun' },
      { member_name: '민재', member_id: 'min', avatar_url: 'https://i.pravatar.cc/150?u=min' },
      { member_name: '도윤', member_id: 'do', avatar_url: 'https://i.pravatar.cc/150?u=do' },
      { member_name: '시우', member_id: 'si', avatar_url: 'https://i.pravatar.cc/150?u=si' },
      { member_name: '하준', member_id: 'ha', avatar_url: 'https://i.pravatar.cc/150?u=ha' },
    ],
    has_member_selection: true,
    included_items: [
      { name: '정규 앨범', quantity: 1 },
      { name: '팬사인회 응모권', quantity: 1 },
      { name: '미공개 셀카 포토카드', quantity: 1 },
      { name: '권협 생일 포토카드', quantity: 1, description: '당첨자 한정' },
    ],
    shipping_info: '팬사인회 현장 수령 또는 택배 발송',
    images: [
      { url: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400', caption: '앨범 이미지' },
    ],
  },
  {
    id: 't3',
    campaign_id: '1',
    title: '영상통화 응모권',
    description: '앨범 1장 + 1:1 영상통화 응모권 (멤버 선택 필수)',
    price_dt: 800,
    total_quantity: 50,
    remaining_quantity: 0,
    display_order: 2,
    is_active: true,
    is_featured: false,
    pledge_count: 50,
    estimated_delivery_at: '2026-02-10T00:00:00Z',
    created_at: '2026-01-25T00:00:00Z',
    updated_at: '2026-01-25T00:00:00Z',

    badge_type: 'limited',
    badge_label: '마감',
    member_options: [
      { member_name: '권협', member_id: 'kwon', avatar_url: 'https://i.pravatar.cc/150?u=kwon' },
      { member_name: '준서', member_id: 'jun', avatar_url: 'https://i.pravatar.cc/150?u=jun' },
      { member_name: '민재', member_id: 'min', avatar_url: 'https://i.pravatar.cc/150?u=min' },
      { member_name: '도윤', member_id: 'do', avatar_url: 'https://i.pravatar.cc/150?u=do' },
      { member_name: '시우', member_id: 'si', avatar_url: 'https://i.pravatar.cc/150?u=si' },
      { member_name: '하준', member_id: 'ha', avatar_url: 'https://i.pravatar.cc/150?u=ha' },
    ],
    has_member_selection: true,
    included_items: [
      { name: '정규 앨범', quantity: 1 },
      { name: '영상통화 응모권', quantity: 1 },
      { name: '미공개 셀카 포토카드', quantity: 1 },
    ],
    shipping_info: '택배 발송',
    images: [],
  },
  {
    id: 't4',
    campaign_id: '1',
    title: 'VIP 올인원 패키지',
    description: '앨범 2장 + 팬사인회 + 영상통화 + 모든 특전',
    price_dt: 2000,
    total_quantity: 10,
    remaining_quantity: 2,
    display_order: 3,
    is_active: true,
    is_featured: false,
    pledge_count: 8,
    estimated_delivery_at: '2026-02-20T00:00:00Z',
    created_at: '2026-01-25T00:00:00Z',
    updated_at: '2026-01-25T00:00:00Z',

    badge_type: 'best',
    badge_label: 'BEST',
    member_options: [
      { member_name: '권협', member_id: 'kwon', avatar_url: 'https://i.pravatar.cc/150?u=kwon' },
      { member_name: '준서', member_id: 'jun', avatar_url: 'https://i.pravatar.cc/150?u=jun' },
      { member_name: '민재', member_id: 'min', avatar_url: 'https://i.pravatar.cc/150?u=min' },
      { member_name: '도윤', member_id: 'do', avatar_url: 'https://i.pravatar.cc/150?u=do' },
      { member_name: '시우', member_id: 'si', avatar_url: 'https://i.pravatar.cc/150?u=si' },
      { member_name: '하준', member_id: 'ha', avatar_url: 'https://i.pravatar.cc/150?u=ha' },
    ],
    has_member_selection: true,
    included_items: [
      { name: '정규 앨범', quantity: 2 },
      { name: '팬사인회 참석 확정권', quantity: 1, description: '추첨 없이 확정' },
      { name: '영상통화 확정권', quantity: 1, description: '추첨 없이 확정' },
      { name: '미공개 셀카 포토카드', quantity: 6, description: '전종 세트' },
      { name: '권협 생일 포토카드', quantity: 1 },
      { name: 'VIP 기념 키링', quantity: 1 },
    ],
    shipping_info: '특별 포장 택배 발송',
    images: [],
  },

  // Campaign 2 Tiers
  {
    id: 't5',
    campaign_id: '2',
    title: '일반석 티켓',
    description: '콘서트 일반석 1매',
    price_dt: 300,
    total_quantity: 300,
    remaining_quantity: 120,
    display_order: 0,
    is_active: true,
    is_featured: false,
    pledge_count: 180,
    estimated_delivery_at: '2026-03-20T00:00:00Z',
    created_at: '2026-01-15T00:00:00Z',
    updated_at: '2026-01-15T00:00:00Z',

    badge_type: null,
    member_options: [],
    has_member_selection: false,
    included_items: [
      { name: '콘서트 티켓', quantity: 1 },
      { name: '공연 포스터 (사인본)', quantity: 1 },
    ],
    shipping_info: '모바일 티켓 발송',
    images: [],
  },
  {
    id: 't6',
    campaign_id: '2',
    title: 'VIP석 티켓',
    description: '무대 앞 VIP석 1매 + 사운드체크 참관',
    price_dt: 800,
    total_quantity: 50,
    remaining_quantity: 12,
    display_order: 1,
    is_active: true,
    is_featured: true,
    pledge_count: 38,
    estimated_delivery_at: '2026-03-20T00:00:00Z',
    created_at: '2026-01-15T00:00:00Z',
    updated_at: '2026-01-15T00:00:00Z',

    badge_type: 'limited',
    badge_label: '한정',
    member_options: [],
    has_member_selection: false,
    included_items: [
      { name: 'VIP 콘서트 티켓', quantity: 1 },
      { name: '사운드체크 참관권', quantity: 1 },
      { name: '공연 포스터 (사인본)', quantity: 1 },
      { name: 'VIP 기념 굿즈', quantity: 1 },
    ],
    shipping_info: '현장 수령',
    images: [],
  },

  // Campaign 3 Tiers
  {
    id: 't7',
    campaign_id: '3',
    title: '화보집 기본',
    description: '화보집 1권',
    price_dt: 200,
    total_quantity: null,
    remaining_quantity: null,
    display_order: 0,
    is_active: true,
    is_featured: false,
    pledge_count: 120,
    estimated_delivery_at: '2026-03-01T00:00:00Z',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',

    badge_type: null,
    member_options: [],
    has_member_selection: false,
    included_items: [
      { name: '화보집', quantity: 1, description: '80P' },
    ],
    shipping_info: '국내 무료 배송',
    images: [],
  },
  {
    id: 't8',
    campaign_id: '3',
    title: '화보집 스페셜',
    description: '화보집 1권 + 포토카드 세트 + 포스터',
    price_dt: 400,
    total_quantity: 100,
    remaining_quantity: 31,
    display_order: 1,
    is_active: true,
    is_featured: true,
    pledge_count: 69,
    estimated_delivery_at: '2026-03-01T00:00:00Z',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',

    badge_type: 'recommended',
    badge_label: '추천',
    member_options: [],
    has_member_selection: false,
    included_items: [
      { name: '화보집', quantity: 1 },
      { name: '포토카드 세트', quantity: 1, description: '6종' },
      { name: '접지 포스터', quantity: 1 },
      { name: '북마크 세트', quantity: 1 },
    ],
    shipping_info: '특별 포장 택배 발송',
    images: [],
  },
]

// ============================================
// FAQs
// ============================================
export const mockFAQs: FaqItem[] = [
  // Campaign 1 FAQs
  {
    id: 'faq1',
    campaign_id: '1',
    question: '배송은 언제 되나요?',
    answer: '펀딩 종료 후 약 2주 내에 순차 발송 예정입니다. 팬사인회/영상통화 당첨자는 이벤트 종료 후 발송됩니다.',
    display_order: 0,
    created_at: '2026-01-25T00:00:00Z',
    updated_at: '2026-01-25T00:00:00Z',
  },
  {
    id: 'faq2',
    campaign_id: '1',
    question: '해외 배송도 가능한가요?',
    answer: '네, 해외 배송 가능합니다. 단, 해외 배송비(국가별 상이)는 별도 결제가 필요합니다. 팬사인회 현장 참여는 국내 거주자만 가능합니다.',
    display_order: 1,
    created_at: '2026-01-25T00:00:00Z',
    updated_at: '2026-01-25T00:00:00Z',
  },
  {
    id: 'faq3',
    campaign_id: '1',
    question: '멤버 선택은 어떻게 하나요?',
    answer: '결제 시 옵션에서 원하시는 멤버를 선택하시면 됩니다. 선택하신 멤버와 팬사인회/영상통화를 진행하게 됩니다.',
    display_order: 2,
    created_at: '2026-01-25T00:00:00Z',
    updated_at: '2026-01-25T00:00:00Z',
  },
  {
    id: 'faq4',
    campaign_id: '1',
    question: '당첨 확률은 어떻게 되나요?',
    answer: '팬사인회는 약 50%, 영상통화는 약 30%의 당첨 확률을 예상하고 있습니다. 정확한 확률은 참여 인원에 따라 변동됩니다.',
    display_order: 3,
    created_at: '2026-01-25T00:00:00Z',
    updated_at: '2026-01-25T00:00:00Z',
  },
  // Campaign 2 FAQs
  {
    id: 'faq5',
    campaign_id: '2',
    question: '목표 금액 미달성 시 어떻게 되나요?',
    answer: '펀딩 목표 금액 미달성 시 전액 환불됩니다. 결제하신 DT가 지갑으로 반환됩니다.',
    display_order: 0,
    created_at: '2026-01-15T00:00:00Z',
    updated_at: '2026-01-15T00:00:00Z',
  },
  // Campaign 3 FAQs
  {
    id: 'faq6',
    campaign_id: '3',
    question: '화보집 사양이 어떻게 되나요?',
    answer: '양장본, 80페이지, A4 사이즈입니다. 고급 무광 용지에 인쇄됩니다.',
    display_order: 0,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
]

// ============================================
// Updates
// ============================================
export const mockUpdates: CampaignUpdate_[] = [
  {
    id: 'u1',
    campaign_id: '1',
    title: '🎉 70% 달성! 감사합니다!',
    content_md: '여러분 덕분에 목표 금액의 70%를 달성했습니다!\n\n첫 번째 스트레치 골도 달성하여 포토카드 2종이 추가됩니다.\n\n남은 기간 동안 많은 관심 부탁드립니다 💜',
    content_html: '<p>여러분 덕분에 목표 금액의 70%를 달성했습니다!</p><p>첫 번째 스트레치 골도 달성하여 포토카드 2종이 추가됩니다.</p><p>남은 기간 동안 많은 관심 부탁드립니다 💜</p>',
    is_public: true,
    view_count: 1250,
    created_at: '2026-02-04T12:00:00Z',
    updated_at: '2026-02-04T12:00:00Z',
  },
  {
    id: 'u2',
    campaign_id: '1',
    title: '펀딩 오픈 안내',
    content_md: 'WAKER 3rd Mini Album 펀딩이 오픈되었습니다!\n\n권협 생일 기념 특별 이벤트와 함께 진행됩니다.',
    content_html: null,
    is_public: true,
    view_count: 2340,
    created_at: '2026-02-03T15:00:00Z',
    updated_at: '2026-02-03T15:00:00Z',
  },
  {
    id: 'u3',
    campaign_id: '2',
    title: '첫 번째 스트레치 골 달성!',
    content_md: 'VIP 좌석 50석이 추가됩니다! 감사합니다! 🌙',
    content_html: null,
    is_public: true,
    view_count: 890,
    created_at: '2026-02-10T18:00:00Z',
    updated_at: '2026-02-10T18:00:00Z',
  },
]

// ============================================
// Comments
// ============================================
export const mockComments: CampaignComment[] = [
  {
    id: 'c1',
    campaign_id: '1',
    user_id: 'user-1',
    content: '권협 생일 축하해요! 🎂 이번 앨범 정말 기대됩니다!',
    is_creator_reply: false,
    is_pinned: false,
    like_count: 45,
    created_at: '2026-02-03T16:30:00Z',
    updated_at: '2026-02-03T16:30:00Z',
    user: {
      id: 'user-1',
      role: 'fan',
      display_name: '협이최고',
      avatar_url: 'https://i.pravatar.cc/150?u=user1',
      bio: null,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    replies: [
      {
        id: 'c1-r1',
        campaign_id: '1',
        user_id: 'demo-creator-1',
        parent_id: 'c1',
        content: '감사합니다! 많은 관심 부탁드려요 💜',
        is_creator_reply: true,
        is_pinned: false,
        like_count: 120,
        created_at: '2026-02-03T17:00:00Z',
        updated_at: '2026-02-03T17:00:00Z',
        user: mockCreators['demo-creator-1'],
      },
    ],
  },
  {
    id: 'c2',
    campaign_id: '1',
    user_id: 'user-2',
    content: '해외 배송비가 얼마인지 알 수 있을까요?',
    is_creator_reply: false,
    is_pinned: false,
    like_count: 12,
    created_at: '2026-02-04T09:15:00Z',
    updated_at: '2026-02-04T09:15:00Z',
    user: {
      id: 'user-2',
      role: 'fan',
      display_name: 'GlobalFan',
      avatar_url: 'https://i.pravatar.cc/150?u=user2',
      bio: null,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
    replies: [],
  },
]

// ============================================
// Reviews
// ============================================
export const mockReviews: CampaignReview[] = [
  {
    id: 'r1',
    campaign_id: '3',
    pledge_id: 'p1',
    user_id: 'user-3',
    rating: 5,
    title: '화보집 퀄리티 최고!',
    content: '인쇄 품질도 좋고 사진도 정말 예쁘게 나왔어요. 스트레치 골로 받은 포토카드도 대만족입니다!',
    images: [],
    is_verified_purchase: true,
    helpful_count: 28,
    created_at: '2026-03-05T14:00:00Z',
    user: {
      id: 'user-3',
      role: 'fan',
      display_name: '별빛팬',
      avatar_url: 'https://i.pravatar.cc/150?u=user3',
      bio: null,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
  },
  {
    id: 'r2',
    campaign_id: '3',
    pledge_id: 'p2',
    user_id: 'user-4',
    rating: 4,
    title: '전체적으로 만족',
    content: '화보집 구성이 알차고 좋아요. 다만 배송이 조금 늦어진 점이 아쉬웠습니다.',
    images: [],
    is_verified_purchase: true,
    helpful_count: 15,
    created_at: '2026-03-08T10:30:00Z',
    user: {
      id: 'user-4',
      role: 'fan',
      display_name: 'StarFan',
      avatar_url: 'https://i.pravatar.cc/150?u=user4',
      bio: null,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
    },
  },
]

// ============================================
// Platform Policies (Wadiz Style)
// ============================================
export const mockPolicies: PlatformPolicy[] = [
  {
    id: 'policy-1',
    slug: 'terms-service',
    category: 'general',
    title: '서비스 이용약관',
    title_en: 'Terms of Service',
    content_html: `
      <h2 id="article-1">제1조 (목적)</h2>
      <p>본 약관은 UNO A(이하 "회사")가 제공하는 서비스의 이용과 관련하여 회사와 회원 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.</p>

      <h2 id="article-2">제2조 (정의)</h2>
      <p>본 약관에서 사용하는 용어의 정의는 다음과 같습니다.</p>
      <ol>
        <li>"서비스"란 회사가 제공하는 펀딩 플랫폼 및 관련 서비스를 말합니다.</li>
        <li>"회원"이란 본 약관에 동의하고 서비스를 이용하는 자를 말합니다.</li>
        <li>"크리에이터"란 펀딩 캠페인을 개설하여 후원을 받는 회원을 말합니다.</li>
        <li>"서포터"란 펀딩 캠페인에 후원하는 회원을 말합니다.</li>
      </ol>

      <h2 id="article-3">제3조 (약관의 효력 및 변경)</h2>
      <p>① 본 약관은 서비스 화면에 게시하거나 기타의 방법으로 회원에게 공지함으로써 효력이 발생합니다.</p>
      <p>② 회사는 관련 법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있습니다.</p>
    `,
    version: '2026.01.15',
    effective_at: '2026-01-15T00:00:00Z',
    toc: [
      { id: '1', title: '제1조 (목적)', anchor: 'article-1' },
      { id: '2', title: '제2조 (정의)', anchor: 'article-2' },
      { id: '3', title: '제3조 (약관의 효력 및 변경)', anchor: 'article-3' },
    ],
    is_active: true,
    is_required: true,
    update_notes: '서비스 명칭 변경 반영',
    created_at: '2026-01-15T00:00:00Z',
    updated_at: '2026-01-15T00:00:00Z',
  },
  {
    id: 'policy-2',
    slug: 'privacy-policy',
    category: 'privacy',
    title: '개인정보처리방침',
    title_en: 'Privacy Policy',
    content_html: `
      <h2 id="section-1">1. 개인정보의 수집 및 이용 목적</h2>
      <p>회사는 다음의 목적을 위하여 개인정보를 처리합니다.</p>
      <ul>
        <li>회원 가입 및 관리</li>
        <li>서비스 제공 및 운영</li>
        <li>결제 및 정산</li>
        <li>마케팅 및 광고 활용</li>
      </ul>

      <h2 id="section-2">2. 수집하는 개인정보 항목</h2>
      <p>회사는 서비스 제공을 위해 다음과 같은 개인정보를 수집합니다.</p>
      <ul>
        <li>필수항목: 이메일, 비밀번호, 닉네임</li>
        <li>선택항목: 프로필 이미지, 연락처</li>
      </ul>
    `,
    version: '2026.01.20',
    effective_at: '2026-01-20T00:00:00Z',
    toc: [
      { id: '1', title: '1. 개인정보의 수집 및 이용 목적', anchor: 'section-1' },
      { id: '2', title: '2. 수집하는 개인정보 항목', anchor: 'section-2' },
    ],
    is_active: true,
    is_required: true,
    update_notes: '마케팅 정보 수신 동의 항목 추가',
    created_at: '2026-01-20T00:00:00Z',
    updated_at: '2026-01-20T00:00:00Z',
  },
  {
    id: 'policy-3',
    slug: 'funding-terms',
    category: 'funding',
    title: '펀딩 이용약관',
    content_html: `
      <h2 id="funding-1">제1조 (펀딩의 정의)</h2>
      <p>펀딩이란 크리에이터가 제시한 프로젝트에 서포터가 후원금을 지원하고, 목표 달성 시 리워드를 수령하는 방식의 크라우드펀딩을 말합니다.</p>

      <h2 id="funding-2">제2조 (펀딩 참여)</h2>
      <p>① 서포터는 원하는 리워드를 선택하여 펀딩에 참여할 수 있습니다.</p>
      <p>② 펀딩 금액은 DT(디지털 토큰)로 결제됩니다.</p>
    `,
    version: '2026.01.15',
    effective_at: '2026-01-15T00:00:00Z',
    toc: [
      { id: '1', title: '제1조 (펀딩의 정의)', anchor: 'funding-1' },
      { id: '2', title: '제2조 (펀딩 참여)', anchor: 'funding-2' },
    ],
    is_active: true,
    is_required: false,
    created_at: '2026-01-15T00:00:00Z',
    updated_at: '2026-01-15T00:00:00Z',
  },
  {
    id: 'policy-4',
    slug: 'refund-policy',
    category: 'funding',
    title: '환불 정책',
    content_html: `
      <h2>환불 기준</h2>
      <p>펀딩 후원금의 환불은 다음과 같은 기준에 따릅니다.</p>
      <ul>
        <li><strong>펀딩 진행 중:</strong> 펀딩 종료 전까지 자유롭게 취소 및 환불 가능</li>
        <li><strong>펀딩 성공 후:</strong> 리워드 발송 전까지 환불 요청 가능 (수수료 10% 공제)</li>
        <li><strong>리워드 발송 후:</strong> 상품 하자 시에만 환불 가능</li>
      </ul>
    `,
    version: '2026.01.15',
    effective_at: '2026-01-15T00:00:00Z',
    toc: [],
    is_active: true,
    is_required: false,
    created_at: '2026-01-15T00:00:00Z',
    updated_at: '2026-01-15T00:00:00Z',
  },
]

// ============================================
// Mock user for demo
// ============================================
export const mockDemoUser = {
  id: 'demo-user',
  email: 'demo@unoa.app',
  role: 'fan' as const, // SECURITY: Demo user must not have admin role
}

// ============================================
// Helper Functions
// ============================================
export function getCampaignBySlug(slug: string): CampaignEnhanced | null {
  return mockCampaigns.find(c => c.slug === slug) || null
}

export function getCampaignById(id: string): CampaignEnhanced | null {
  return mockCampaigns.find(c => c.id === id) || null
}

export function getTiersByCampaignId(campaignId: string): RewardTierEnhanced[] {
  return mockTiers.filter(t => t.campaign_id === campaignId)
}

export function getFAQsByCampaignId(campaignId: string): FaqItem[] {
  return mockFAQs.filter(f => f.campaign_id === campaignId)
}

export function getUpdatesByCampaignId(campaignId: string): CampaignUpdate_[] {
  return mockUpdates.filter(u => u.campaign_id === campaignId)
}

export function getCommentsByCampaignId(campaignId: string): CampaignComment[] {
  return mockComments.filter(c => c.campaign_id === campaignId && !c.parent_id)
}

export function getReviewsByCampaignId(campaignId: string): CampaignReview[] {
  return mockReviews.filter(r => r.campaign_id === campaignId)
}

export function getRelatedCampaigns(campaignIds: string[]): CampaignEnhanced[] {
  return mockCampaigns.filter(c => campaignIds.includes(c.id))
}

export function getPolicyBySlug(slug: string): PlatformPolicy | null {
  return mockPolicies.find(p => p.slug === slug) || null
}

export function getPoliciesByCategory(category: string): PlatformPolicy[] {
  return mockPolicies.filter(p => p.category === category)
}

export function getAllPolicies(): PlatformPolicy[] {
  return mockPolicies
}

// Export campaign IDs/slugs for static params
export function getMockCampaignIds(): string[] {
  return mockCampaigns.map(c => c.id)
}

export function getMockCampaignSlugs(): string[] {
  return mockCampaigns.map(c => c.slug)
}

export function getMockPolicySlugs(): string[] {
  return mockPolicies.map(p => p.slug)
}

// Full campaign data for detail page
export function getCampaignFullData(slug: string) {
  const campaign = getCampaignBySlug(slug)
  if (!campaign) return null

  return {
    campaign,
    tiers: getTiersByCampaignId(campaign.id),
    faqs: getFAQsByCampaignId(campaign.id),
    updates: getUpdatesByCampaignId(campaign.id),
    comments: getCommentsByCampaignId(campaign.id),
    reviews: getReviewsByCampaignId(campaign.id),
  }
}
