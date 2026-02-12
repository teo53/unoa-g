-- =====================================================
-- Migration 051: Storage 버킷 정책 강화
--
-- 문제:
--   1. INSERT 정책이 인증만 확인 → 아무 유저나 업로드 가능
--   2. DELETE 정책은 user_id/ 경로 기대하지만 실제는 campaign-{id}/ 경로
--
-- 수정:
--   - campaign-{id} 경로: funding_campaigns.creator_id 검증
--   - 기타 경로: auth.uid()로 시작하는 폴더만 허용
-- =====================================================

-- =====================================================
-- 1. campaign-images 버킷 — 기존 INSERT/DELETE 정책 교체
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can upload campaign images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own campaign images" ON storage.objects;

-- INSERT: 캠페인 경로는 소유자만, 그 외는 user_id 폴더
CREATE POLICY "Campaign creators can upload campaign images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'campaign-images' AND
  (
    CASE
      WHEN name LIKE 'campaign-%' THEN
        EXISTS (
          SELECT 1 FROM public.funding_campaigns
          WHERE id = (regexp_match(name, '^campaign-([a-f0-9-]+)/'))[1]::uuid
          AND creator_id = auth.uid()
        )
      ELSE
        auth.uid()::text = (string_to_array(name, '/'))[1]
    END
  )
);

-- DELETE: 동일한 소유자 검증
CREATE POLICY "Campaign creators can delete campaign images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'campaign-images' AND
  (
    CASE
      WHEN name LIKE 'campaign-%' THEN
        EXISTS (
          SELECT 1 FROM public.funding_campaigns
          WHERE id = (regexp_match(name, '^campaign-([a-f0-9-]+)/'))[1]::uuid
          AND creator_id = auth.uid()
        )
      ELSE
        auth.uid()::text = (string_to_array(name, '/'))[1]
    END
  )
);

-- SELECT(public): 기존 정책 유지 (이미 존재)

-- =====================================================
-- 2. team-avatars 버킷 — 기존 INSERT/DELETE 정책 교체
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can upload team avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own team avatars" ON storage.objects;

CREATE POLICY "Campaign creators can upload team avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'team-avatars' AND
  (
    CASE
      WHEN name LIKE 'campaign-%' THEN
        EXISTS (
          SELECT 1 FROM public.funding_campaigns
          WHERE id = (regexp_match(name, '^campaign-([a-f0-9-]+)/'))[1]::uuid
          AND creator_id = auth.uid()
        )
      ELSE
        auth.uid()::text = (string_to_array(name, '/'))[1]
    END
  )
);

CREATE POLICY "Campaign creators can delete team avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'team-avatars' AND
  (
    CASE
      WHEN name LIKE 'campaign-%' THEN
        EXISTS (
          SELECT 1 FROM public.funding_campaigns
          WHERE id = (regexp_match(name, '^campaign-([a-f0-9-]+)/'))[1]::uuid
          AND creator_id = auth.uid()
        )
      ELSE
        auth.uid()::text = (string_to_array(name, '/'))[1]
    END
  )
);

-- =====================================================
-- 3. benefit-images 버킷 — 기존 INSERT/DELETE 정책 교체
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can upload benefit images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own benefit images" ON storage.objects;

CREATE POLICY "Campaign creators can upload benefit images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'benefit-images' AND
  (
    CASE
      WHEN name LIKE 'campaign-%' THEN
        EXISTS (
          SELECT 1 FROM public.funding_campaigns
          WHERE id = (regexp_match(name, '^campaign-([a-f0-9-]+)/'))[1]::uuid
          AND creator_id = auth.uid()
        )
      ELSE
        auth.uid()::text = (string_to_array(name, '/'))[1]
    END
  )
);

CREATE POLICY "Campaign creators can delete benefit images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'benefit-images' AND
  (
    CASE
      WHEN name LIKE 'campaign-%' THEN
        EXISTS (
          SELECT 1 FROM public.funding_campaigns
          WHERE id = (regexp_match(name, '^campaign-([a-f0-9-]+)/'))[1]::uuid
          AND creator_id = auth.uid()
        )
      ELSE
        auth.uid()::text = (string_to_array(name, '/'))[1]
    END
  )
);
