-- ========================================================
-- DELIVERY PROBLEMS TABLE - Teslimat Sorun Bildirimi
-- ========================================================
-- Kuryelerin teslimat sırasında karşılaştıkları sorunları
-- kaydetmek için kullanılır
-- ========================================================

-- Tablo oluştur
CREATE TABLE IF NOT EXISTS delivery_problems (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_request_id UUID NOT NULL REFERENCES delivery_requests(id) ON DELETE CASCADE,
  courier_id UUID NOT NULL REFERENCES users(id),
  merchant_id UUID NOT NULL REFERENCES users(id),
  problem_type TEXT NOT NULL CHECK (problem_type IN (
    '📍 Adres Yanlış/Eksik',
    '📞 Müşteri Telefonu Çalışmıyor',
    '🏠 Müşteri Evde Yok',
    '📦 Paket Bilgisi Uyuşmuyor',
    '💳 Ödeme Sorunu',
    '🚗 Araç Arızası',
    '🔧 Diğer'
  )),
  problem_note TEXT,
  status TEXT DEFAULT 'reported' CHECK (status IN ('reported', 'resolved', 'escalated')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  admin_notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index'ler
CREATE INDEX IF NOT EXISTS idx_delivery_problems_delivery_id ON delivery_problems(delivery_request_id);
CREATE INDEX IF NOT EXISTS idx_delivery_problems_courier_id ON delivery_problems(courier_id);
CREATE INDEX IF NOT EXISTS idx_delivery_problems_merchant_id ON delivery_problems(merchant_id);
CREATE INDEX IF NOT EXISTS idx_delivery_problems_status ON delivery_problems(status);
CREATE INDEX IF NOT EXISTS idx_delivery_problems_created_at ON delivery_problems(created_at DESC);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_delivery_problems_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_delivery_problems_updated_at ON delivery_problems;
CREATE TRIGGER trigger_delivery_problems_updated_at
  BEFORE UPDATE ON delivery_problems
  FOR EACH ROW
  EXECUTE FUNCTION update_delivery_problems_updated_at();

-- RLS Politikaları
ALTER TABLE delivery_problems ENABLE ROW LEVEL SECURITY;

-- Kuryeler kendi sorunlarını görebilir ve oluşturabilir
DROP POLICY IF EXISTS "Couriers can view their own problem reports" ON delivery_problems;
CREATE POLICY "Couriers can view their own problem reports"
  ON delivery_problems FOR SELECT
  USING (
    courier_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'courier'
    )
  );

DROP POLICY IF EXISTS "Couriers can create problem reports" ON delivery_problems;
CREATE POLICY "Couriers can create problem reports"
  ON delivery_problems FOR INSERT
  WITH CHECK (
    courier_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'courier'
    )
  );

-- Merchantlar kendi siparişleriyle ilgili sorunları görebilir
DROP POLICY IF EXISTS "Merchants can view problems for their orders" ON delivery_problems;
CREATE POLICY "Merchants can view problems for their orders"
  ON delivery_problems FOR SELECT
  USING (
    merchant_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'merchant'
    )
  );

-- Adminler her şeyi görebilir ve güncelleyebilir
DROP POLICY IF EXISTS "Admins can view all problem reports" ON delivery_problems;
CREATE POLICY "Admins can view all problem reports"
  ON delivery_problems FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can update problem reports" ON delivery_problems;
CREATE POLICY "Admins can update problem reports"
  ON delivery_problems FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- ========================================================
-- TEST VERİSİ (İSTEĞE BAĞLI)
-- ========================================================
-- Test için örnek sorun kaydı eklemek isterseniz:
-- INSERT INTO delivery_problems (
--   delivery_request_id,
--   courier_id,
--   merchant_id,
--   problem_type,
--   problem_note
-- ) VALUES (
--   'teslimat-id-buraya',
--   'kurye-id-buraya',
--   'merchant-id-buraya',
--   '📞 Müşteri Telefonu Çalışmıyor',
--   'Müşteri telefonuna ulaşamıyorum, lütfen alternatif iletişim sağlayın'
-- );

COMMENT ON TABLE delivery_problems IS 'Kuryelerin teslimat sırasında bildirdiği sorunlar';
COMMENT ON COLUMN delivery_problems.problem_type IS 'Sorun tipi (emoji ile)';
COMMENT ON COLUMN delivery_problems.status IS 'Sorun durumu: reported, resolved, escalated';
COMMENT ON COLUMN delivery_problems.admin_notes IS 'Admin notları ve çözüm detayları';
