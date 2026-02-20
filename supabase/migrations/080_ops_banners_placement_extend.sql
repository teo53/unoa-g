-- ============================================================
-- Migration 080: ops_banners.placement CHECK 제약 확장
-- chat_list, funding_top placement 추가.
-- ops-types.ts BannerPlacement 타입과 동기화.
-- ============================================================

-- PostgreSQL 인라인 CHECK 제약의 자동 생성 이름은
-- {table}_{column}_check 패턴. 존재 시 DROP 후 재생성.
ALTER TABLE public.ops_banners
  DROP CONSTRAINT IF EXISTS ops_banners_placement_check;

ALTER TABLE public.ops_banners
  ADD CONSTRAINT ops_banners_placement_check
  CHECK (placement IN (
    'home_top',
    'home_bottom',
    'discover_top',
    'chat_top',
    'chat_list',
    'profile_banner',
    'funding_top',
    'popup'
  ));

COMMENT ON COLUMN public.ops_banners.placement IS
  'home_top | home_bottom | discover_top | chat_top | chat_list | profile_banner | funding_top | popup';
