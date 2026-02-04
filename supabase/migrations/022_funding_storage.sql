-- ============================================
-- UNO A - Funding Storage Buckets
-- Version: 1.0.0
-- Description: Storage buckets for campaign images and files
-- ============================================

-- Note: Storage bucket creation is typically done via Supabase Dashboard
-- This file documents the required buckets and policies

-- ============================================
-- 1. CREATE STORAGE BUCKETS (via Dashboard or API)
-- ============================================

-- Bucket: campaign-images
-- Description: Public bucket for campaign cover images and story images
-- Settings:
--   - Public: true
--   - File size limit: 10MB
--   - Allowed MIME types: image/jpeg, image/png, image/webp, image/gif

-- Bucket: campaign-files
-- Description: Private bucket for campaign attachments (PDFs, etc.)
-- Settings:
--   - Public: false
--   - File size limit: 50MB
--   - Allowed MIME types: application/pdf, video/*

-- ============================================
-- 2. STORAGE POLICIES
-- ============================================

-- Note: These policies need to be applied via Supabase Dashboard
-- or using the storage-api. SQL-based policies for storage
-- work differently than regular RLS.

-- The following is documentation of the intended policies:

/*
-- Campaign Images Bucket Policies

-- Policy: Public read access
-- Allows anyone to read images
{
  "name": "Public read access",
  "definition": "true",
  "operation": "SELECT"
}

-- Policy: Authenticated users can upload to their folder
-- Allows creators to upload images
{
  "name": "Creators can upload images",
  "definition": "auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text",
  "operation": "INSERT"
}

-- Policy: Creators can update their own images
{
  "name": "Creators can update their images",
  "definition": "auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text",
  "operation": "UPDATE"
}

-- Policy: Creators can delete their own images
{
  "name": "Creators can delete their images",
  "definition": "auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text",
  "operation": "DELETE"
}

-- Campaign Files Bucket Policies

-- Policy: Authenticated users can read files they have access to
{
  "name": "Authenticated read access",
  "definition": "auth.role() = 'authenticated'",
  "operation": "SELECT"
}

-- Policy: Creators can upload files
{
  "name": "Creators can upload files",
  "definition": "auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text",
  "operation": "INSERT"
}
*/

-- ============================================
-- 3. HELPER FUNCTION FOR GENERATING STORAGE PATHS
-- ============================================

-- Generate a unique path for campaign images
CREATE OR REPLACE FUNCTION public.generate_campaign_image_path(
  p_user_id UUID,
  p_campaign_id UUID,
  p_filename TEXT
)
RETURNS TEXT AS $$
DECLARE
  v_extension TEXT;
  v_safe_filename TEXT;
BEGIN
  -- Extract extension
  v_extension := lower(substring(p_filename from '\.([^.]+)$'));

  -- Generate safe filename with timestamp
  v_safe_filename := p_user_id::text || '/' || p_campaign_id::text || '/' ||
    extract(epoch from now())::bigint || '_' ||
    encode(gen_random_bytes(8), 'hex') || '.' || COALESCE(v_extension, 'jpg');

  RETURN v_safe_filename;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 4. IMAGE URL VALIDATION
-- ============================================

-- Validate that a URL is from our storage or allowed external sources
CREATE OR REPLACE FUNCTION public.is_valid_image_url(p_url TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  IF p_url IS NULL THEN
    RETURN true;
  END IF;

  -- Allow Supabase storage URLs
  IF p_url LIKE '%supabase.co/storage/v1/object/%' THEN
    RETURN true;
  END IF;

  IF p_url LIKE '%supabase.in/storage/v1/object/%' THEN
    RETURN true;
  END IF;

  -- Allow common image CDNs (optional)
  IF p_url LIKE 'https://images.unsplash.com/%' THEN
    RETURN true;
  END IF;

  IF p_url LIKE 'https://cdn.%' THEN
    RETURN true;
  END IF;

  -- For development, allow any https URL
  IF p_url LIKE 'https://%' THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 5. ADD IMAGE URL VALIDATION TO CAMPAIGNS
-- ============================================

-- Note: Uncomment to enforce URL validation
-- ALTER TABLE funding_campaigns
--   ADD CONSTRAINT valid_cover_image_url
--   CHECK (is_valid_image_url(cover_image_url));

-- ============================================
-- 6. STORAGE USAGE TRACKING (Optional)
-- ============================================

CREATE TABLE IF NOT EXISTS public.storage_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  bucket_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT NOT NULL DEFAULT 0,
  mime_type TEXT,
  campaign_id UUID REFERENCES funding_campaigns(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_file_path UNIQUE (bucket_name, file_path)
);

CREATE INDEX IF NOT EXISTS idx_storage_usage_user ON storage_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_storage_usage_campaign ON storage_usage(campaign_id);

-- RLS for storage usage tracking
ALTER TABLE storage_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own storage usage"
  ON storage_usage FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "System can insert storage usage"
  ON storage_usage FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Function to track storage usage
CREATE OR REPLACE FUNCTION public.track_storage_usage(
  p_user_id UUID,
  p_bucket_name TEXT,
  p_file_path TEXT,
  p_file_size BIGINT,
  p_mime_type TEXT DEFAULT NULL,
  p_campaign_id UUID DEFAULT NULL
)
RETURNS storage_usage AS $$
DECLARE
  v_record storage_usage;
BEGIN
  INSERT INTO storage_usage (
    user_id, bucket_name, file_path, file_size, mime_type, campaign_id
  ) VALUES (
    p_user_id, p_bucket_name, p_file_path, p_file_size, p_mime_type, p_campaign_id
  )
  ON CONFLICT (bucket_name, file_path) DO UPDATE SET
    file_size = EXCLUDED.file_size,
    campaign_id = COALESCE(EXCLUDED.campaign_id, storage_usage.campaign_id)
  RETURNING * INTO v_record;

  RETURN v_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.track_storage_usage TO authenticated;

-- ============================================
-- 7. CLEANUP ORPHANED FILES (Scheduled Job)
-- ============================================

-- Function to find orphaned storage files
CREATE OR REPLACE FUNCTION public.find_orphaned_campaign_images()
RETURNS TABLE (
  file_path TEXT,
  campaign_id UUID,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    su.file_path,
    su.campaign_id,
    su.created_at
  FROM storage_usage su
  LEFT JOIN funding_campaigns fc ON su.campaign_id = fc.id
  WHERE su.bucket_name = 'campaign-images'
    AND su.campaign_id IS NOT NULL
    AND fc.id IS NULL
    AND su.created_at < now() - interval '7 days';
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.find_orphaned_campaign_images TO service_role;
