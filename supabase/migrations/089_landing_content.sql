-- ============================================
-- 058: Landing Page Content CMS
-- ============================================
-- Stores editable content for the public landing page.
-- Single-row table (id = 'main') for simplicity.
-- Public read (anon), write only for ops staff.

BEGIN;

-- Landing content table
CREATE TABLE IF NOT EXISTS public.landing_content (
  id            TEXT PRIMARY KEY DEFAULT 'main',
  hero_headline TEXT NOT NULL DEFAULT '아티스트와 팬, 가장 가까운 거리',
  hero_subheadline TEXT NOT NULL DEFAULT '프라이빗 메시지로 아티스트와 1:1 소통하고, 펀딩으로 특별한 프로젝트를 함께 만들어요.',
  hero_cta_primary TEXT NOT NULL DEFAULT '앱 다운로드',
  hero_cta_secondary TEXT NOT NULL DEFAULT '펀딩 둘러보기',
  features      JSONB NOT NULL DEFAULT '[
    {"icon":"MessageCircle","title":"프라이빗 메시지","description":"아티스트와 1:1 대화하듯 소통하는 특별한 메시지 경험"},
    {"icon":"CreditCard","title":"펀딩 캠페인","description":"아티스트의 프로젝트를 후원하고 독점 리워드를 받으세요"},
    {"icon":"Heart","title":"프라이빗 카드","description":"특별한 순간을 담은 아티스트 전용 포토카드 컬렉션"},
    {"icon":"Vote","title":"투표 & VS","description":"팬들의 의견을 모아 아티스트와 함께 결정하는 인터랙티브 투표"},
    {"icon":"Cake","title":"기념일 축하","description":"생일, 데뷔일 등 특별한 날을 팬들과 함께 축하해요"},
    {"icon":"Sparkles","title":"AI 답글 추천","description":"크리에이터를 위한 AI 기반 스마트 답글 제안 기능"}
  ]'::jsonb,
  stats         JSONB NOT NULL DEFAULT '[
    {"value":1200,"suffix":"+","label":"크리에이터","prefix":""},
    {"value":58000,"suffix":"+","label":"팬 커뮤니티","prefix":""},
    {"value":3,"suffix":"억+","label":"누적 후원금","prefix":"₩"},
    {"value":120,"suffix":"만+","label":"메시지 교환","prefix":""}
  ]'::jsonb,
  footer_links  JSONB NOT NULL DEFAULT '[
    {"label":"펀딩","href":"/funding"},
    {"label":"크리에이터 스튜디오","href":"/studio"},
    {"label":"이용약관","href":"/settings/terms"},
    {"label":"개인정보처리방침","href":"/settings/privacy"}
  ]'::jsonb,
  images        JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at    TIMESTAMPTZ DEFAULT now(),
  updated_by    UUID REFERENCES auth.users(id)
);

-- Insert default row
INSERT INTO public.landing_content (id) VALUES ('main')
ON CONFLICT (id) DO NOTHING;

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION public.set_landing_content_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_landing_content_updated_at
  BEFORE UPDATE ON public.landing_content
  FOR EACH ROW EXECUTE FUNCTION public.set_landing_content_updated_at();

-- RLS
ALTER TABLE public.landing_content ENABLE ROW LEVEL SECURITY;

-- Public read (anyone, including anon)
CREATE POLICY "landing_content_public_read"
  ON public.landing_content
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Write only for ops staff (using existing ops_staff table check)
CREATE POLICY "landing_content_ops_write"
  ON public.landing_content
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.ops_staff
      WHERE user_id = auth.uid()
        AND role IN ('admin', 'publisher', 'operator')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.ops_staff
      WHERE user_id = auth.uid()
        AND role IN ('admin', 'publisher', 'operator')
    )
  );

COMMIT;
