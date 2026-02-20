-- ============================================
-- 059: Creator Content Public Views
-- ============================================
-- Public views for creator content (drops, events, fancams)
-- Used by fan-facing artist profile to display creator content.

BEGIN;

-- Creator drops (goods/merchandise)
CREATE TABLE IF NOT EXISTS public.creator_drops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id),
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  price_krw INT NOT NULL DEFAULT 0,
  is_sold_out BOOLEAN DEFAULT false,
  is_new BOOLEAN DEFAULT false,
  release_date TIMESTAMPTZ,
  external_url TEXT,
  display_order INT DEFAULT 0,
  status TEXT DEFAULT 'published', -- draft, published, archived
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Creator events (concerts, fan meetings, etc.)
CREATE TABLE IF NOT EXISTS public.creator_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id),
  title TEXT NOT NULL,
  location TEXT NOT NULL,
  event_date TIMESTAMPTZ NOT NULL,
  is_offline BOOLEAN DEFAULT true,
  description TEXT,
  ticket_url TEXT,
  image_url TEXT,
  display_order INT DEFAULT 0,
  status TEXT DEFAULT 'published',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Creator fancams (YouTube videos)
CREATE TABLE IF NOT EXISTS public.creator_fancams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id),
  video_id TEXT NOT NULL, -- YouTube video ID
  title TEXT NOT NULL,
  description TEXT,
  view_count INT DEFAULT 0,
  is_pinned BOOLEAN DEFAULT false,
  display_order INT DEFAULT 0,
  upload_date TIMESTAMPTZ,
  status TEXT DEFAULT 'published',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE public.creator_drops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_fancams ENABLE ROW LEVEL SECURITY;

-- Public read for published content
CREATE POLICY "creator_drops_public_read" ON public.creator_drops
  FOR SELECT TO authenticated USING (status = 'published');

CREATE POLICY "creator_drops_creator_write" ON public.creator_drops
  FOR ALL TO authenticated
  USING (creator_id = auth.uid())
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "creator_events_public_read" ON public.creator_events
  FOR SELECT TO authenticated USING (status = 'published');

CREATE POLICY "creator_events_creator_write" ON public.creator_events
  FOR ALL TO authenticated
  USING (creator_id = auth.uid())
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "creator_fancams_public_read" ON public.creator_fancams
  FOR SELECT TO authenticated USING (status = 'published');

CREATE POLICY "creator_fancams_creator_write" ON public.creator_fancams
  FOR ALL TO authenticated
  USING (creator_id = auth.uid())
  WITH CHECK (creator_id = auth.uid());

COMMIT;
