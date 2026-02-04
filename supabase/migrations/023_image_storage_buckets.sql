-- =============================================================
-- 023_image_storage_buckets.sql
-- Image Upload를 위한 Supabase Storage 버킷 및 정책 설정
-- =============================================================

-- 1. Storage 버킷 생성
-- Note: Supabase Dashboard에서 먼저 버킷을 생성해야 합니다.
-- 아래는 SQL로 버킷을 생성하는 방법입니다.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('campaign-images', 'campaign-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']),
  ('team-avatars', 'team-avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']),
  ('benefit-images', 'benefit-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Storage RLS 정책

-- 2.1 campaign-images 버킷 정책

-- 인증된 사용자만 업로드 가능
CREATE POLICY "Authenticated users can upload campaign images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'campaign-images'
);

-- 모든 사용자가 이미지 조회 가능 (public bucket)
CREATE POLICY "Public can view campaign images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'campaign-images');

-- 소유자만 삭제 가능 (폴더명이 user_id로 시작하는 경우)
CREATE POLICY "Users can delete their own campaign images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'campaign-images' AND
  auth.uid()::text = (string_to_array(name, '/'))[1]
);

-- 2.2 team-avatars 버킷 정책

CREATE POLICY "Authenticated users can upload team avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'team-avatars');

CREATE POLICY "Public can view team avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'team-avatars');

CREATE POLICY "Users can delete their own team avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'team-avatars' AND
  auth.uid()::text = (string_to_array(name, '/'))[1]
);

-- 2.3 benefit-images 버킷 정책

CREATE POLICY "Authenticated users can upload benefit images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'benefit-images');

CREATE POLICY "Public can view benefit images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'benefit-images');

CREATE POLICY "Users can delete their own benefit images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'benefit-images' AND
  auth.uid()::text = (string_to_array(name, '/'))[1]
);

-- 3. 캠페인 생성자만 캠페인 이미지 업로드 가능하도록 하는 고급 정책 (선택적)
-- 이 정책은 campaign-images 버킷에서 campaign-{id} 폴더에 대해
-- 해당 캠페인의 creator_id와 현재 사용자가 일치하는지 검증합니다.

-- 먼저 기존 정책 삭제 후 재생성
-- DROP POLICY IF EXISTS "Authenticated users can upload campaign images" ON storage.objects;

-- CREATE POLICY "Campaign creators can upload campaign images"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (
--   bucket_id = 'campaign-images' AND
--   (
--     -- campaign-{id}/... 형식인 경우 캠페인 소유자 검증
--     CASE
--       WHEN name LIKE 'campaign-%' THEN
--         EXISTS (
--           SELECT 1 FROM funding_campaigns
--           WHERE id = (regexp_match(name, '^campaign-([a-f0-9-]+)/'))[1]::uuid
--           AND creator_id = auth.uid()
--         )
--       ELSE true  -- 그 외 경로는 인증된 사용자 허용
--     END
--   )
-- );

COMMENT ON TABLE storage.objects IS 'Image upload storage for UNO A funding campaigns. Buckets: campaign-images, team-avatars, benefit-images';
