-- =============================================
-- 076: Thank-You Sticker System
-- =============================================
-- 크리에이터가 스티커 팩을 설정하고, 팬이 DT로 구매하여 채팅에 전송

-- 1. sticker_sets 테이블 (크리에이터별 스티커 팩)
CREATE TABLE IF NOT EXISTS sticker_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  price_dt INTEGER NOT NULL DEFAULT 100 CHECK (price_dt >= 0),
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. stickers 테이블 (개별 스티커)
CREATE TABLE IF NOT EXISTS stickers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sticker_set_id UUID NOT NULL REFERENCES sticker_sets(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  image_url TEXT NOT NULL,
  animation_url TEXT,  -- 애니메이션 GIF/Lottie (선택)
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 3. sticker_purchases 테이블 (구매 기록)
CREATE TABLE IF NOT EXISTS sticker_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sticker_set_id UUID NOT NULL REFERENCES sticker_sets(id) ON DELETE CASCADE,
  price_dt INTEGER NOT NULL,
  purchased_at TIMESTAMPTZ DEFAULT now() NOT NULL,

  -- 중복 구매 방지
  UNIQUE(buyer_id, sticker_set_id)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_sticker_sets_channel ON sticker_sets(channel_id);
CREATE INDEX IF NOT EXISTS idx_sticker_sets_creator ON sticker_sets(creator_id);
CREATE INDEX IF NOT EXISTS idx_stickers_set ON stickers(sticker_set_id);
CREATE INDEX IF NOT EXISTS idx_sticker_purchases_buyer ON sticker_purchases(buyer_id);
CREATE INDEX IF NOT EXISTS idx_sticker_purchases_set ON sticker_purchases(sticker_set_id);

-- 4. RLS 정책
ALTER TABLE sticker_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE stickers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sticker_purchases ENABLE ROW LEVEL SECURITY;

-- sticker_sets: 활성 세트는 모두 조회 가능, 생성/수정은 크리에이터만
CREATE POLICY sticker_sets_select ON sticker_sets
  FOR SELECT USING (is_active = true OR creator_id = auth.uid());

CREATE POLICY sticker_sets_insert ON sticker_sets
  FOR INSERT WITH CHECK (creator_id = auth.uid());

CREATE POLICY sticker_sets_update ON sticker_sets
  FOR UPDATE USING (creator_id = auth.uid());

-- stickers: 활성 세트의 스티커는 조회 가능
CREATE POLICY stickers_select ON stickers
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM sticker_sets ss
      WHERE ss.id = sticker_set_id
        AND (ss.is_active = true OR ss.creator_id = auth.uid())
    )
  );

CREATE POLICY stickers_insert ON stickers
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM sticker_sets ss
      WHERE ss.id = sticker_set_id AND ss.creator_id = auth.uid()
    )
  );

-- sticker_purchases: 자신의 구매 기록만
CREATE POLICY sticker_purchases_select ON sticker_purchases
  FOR SELECT USING (buyer_id = auth.uid());

CREATE POLICY sticker_purchases_insert ON sticker_purchases
  FOR INSERT WITH CHECK (buyer_id = auth.uid());

-- 5. 메시지에 스티커 필드 추가
ALTER TABLE messages ADD COLUMN IF NOT EXISTS sticker_id UUID REFERENCES stickers(id);
ALTER TABLE messages ADD COLUMN IF NOT EXISTS sticker_image_url TEXT;

-- message_type에 'sticker' 추가 (기존 CHECK 제약 없으므로 불필요하지만 참고용)
-- messages.message_type은 TEXT 필드이며 클라이언트에서 파싱

-- 6. 스티커 구매 RPC (원자적 DT 차감 + 구매)
CREATE OR REPLACE FUNCTION purchase_sticker_set(
  p_sticker_set_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_price INTEGER;
  v_balance INTEGER;
  v_purchase_id UUID;
BEGIN
  -- 가격 조회
  SELECT price_dt INTO v_price
  FROM sticker_sets
  WHERE id = p_sticker_set_id AND is_active = true;

  IF v_price IS NULL THEN
    RAISE EXCEPTION 'Sticker set not found or inactive';
  END IF;

  -- 이미 구매했는지 확인
  IF EXISTS (
    SELECT 1 FROM sticker_purchases
    WHERE buyer_id = v_user_id AND sticker_set_id = p_sticker_set_id
  ) THEN
    RAISE EXCEPTION 'Already purchased';
  END IF;

  -- 무료 스티커는 바로 구매
  IF v_price = 0 THEN
    INSERT INTO sticker_purchases (buyer_id, sticker_set_id, price_dt)
    VALUES (v_user_id, p_sticker_set_id, 0)
    RETURNING id INTO v_purchase_id;
    RETURN v_purchase_id;
  END IF;

  -- 잔액 확인
  SELECT balance_dt INTO v_balance
  FROM wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_balance IS NULL OR v_balance < v_price THEN
    RAISE EXCEPTION 'Insufficient DT balance';
  END IF;

  -- DT 차감
  UPDATE wallets SET balance_dt = balance_dt - v_price
  WHERE user_id = v_user_id;

  -- 원장 기록
  INSERT INTO wallet_ledger (
    wallet_id, entry_type, amount, balance_after, description, reference_id
  )
  SELECT
    w.id, 'sticker_purchase', -v_price, w.balance_dt - v_price,
    '스티커 팩 구매', p_sticker_set_id::text
  FROM wallets w WHERE w.user_id = v_user_id;

  -- 구매 기록
  INSERT INTO sticker_purchases (buyer_id, sticker_set_id, price_dt)
  VALUES (v_user_id, p_sticker_set_id, v_price)
  RETURNING id INTO v_purchase_id;

  RETURN v_purchase_id;
END;
$$;
