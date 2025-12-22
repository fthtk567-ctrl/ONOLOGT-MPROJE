-- ======================================================================
-- GÖREV 2: MERCHANT MAPPING TABLOSU
-- Yemek App restaurant_id → ONLOG merchant_id eşleştirmesi
-- ======================================================================
-- Tarih: 17 Kasım 2025
-- Kullanım: Supabase Dashboard → SQL Editor → Yeni sorgu → Bu kodu yapıştır → Run
-- ======================================================================

-- 1. Tablo oluştur
CREATE TABLE IF NOT EXISTS onlog_merchant_mapping (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  yemek_app_restaurant_id VARCHAR(100) UNIQUE NOT NULL,
  onlog_merchant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  restaurant_name VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Index'ler ekle (hız için)
CREATE INDEX IF NOT EXISTS idx_yemek_app_restaurant_id 
  ON onlog_merchant_mapping(yemek_app_restaurant_id);

CREATE INDEX IF NOT EXISTS idx_onlog_merchant_id 
  ON onlog_merchant_mapping(onlog_merchant_id);

CREATE INDEX IF NOT EXISTS idx_is_active 
  ON onlog_merchant_mapping(is_active);

-- 3. Otomatik updated_at trigger
CREATE OR REPLACE FUNCTION update_merchant_mapping_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_merchant_mapping_timestamp ON onlog_merchant_mapping;

CREATE TRIGGER trigger_update_merchant_mapping_timestamp
  BEFORE UPDATE ON onlog_merchant_mapping
  FOR EACH ROW
  EXECUTE FUNCTION update_merchant_mapping_timestamp();

-- 4. Yorum ekle
COMMENT ON TABLE onlog_merchant_mapping IS 
  'Yemek App restaurant ID → ONLOG merchant ID mapping';

COMMENT ON COLUMN onlog_merchant_mapping.yemek_app_restaurant_id IS 
  'Yemek App tarafındaki restoran ID (örn: R-1234)';

COMMENT ON COLUMN onlog_merchant_mapping.onlog_merchant_id IS 
  'ONLOG users tablosundaki merchant UUID';

-- 5. Test verisi ekle (gerçek merchant ID ile değiştir!)
-- ⚠️ DİKKAT: Önce ONLOG'da bir merchant hesabı oluştur, UUID'sini buraya yaz
/*
INSERT INTO onlog_merchant_mapping (
  yemek_app_restaurant_id, 
  onlog_merchant_id, 
  restaurant_name
) VALUES (
  'R-TEST-001',
  'BURAYA_GERCEK_MERCHANT_UUID_GELECEK', -- users tablosundan UUID al
  'Test Restoran (Yemek App)'
) ON CONFLICT (yemek_app_restaurant_id) DO NOTHING;
*/

-- 6. Doğrulama
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'onlog_merchant_mapping'
ORDER BY ordinal_position;

-- 7. Örnek: Toplu veri ekleme (Yemek App ekibi restoran listesi gönderdiğinde)
/*
INSERT INTO onlog_merchant_mapping 
  (yemek_app_restaurant_id, onlog_merchant_id, restaurant_name) 
VALUES
  ('R-1234', '550e8400-e29b-41d4-a716-446655440000', 'Pizza House Kadıköy'),
  ('R-5678', '6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'Burger King Beyoğlu'),
  ('R-9012', '7c9e6679-7425-40de-944b-e07fc1f90ae7', 'Dönerci Yaşar Beşiktaş')
ON CONFLICT (yemek_app_restaurant_id) DO NOTHING;
*/

COMMIT;

-- ======================================================================
-- NOTLAR
-- ======================================================================
-- 1. Gerçek merchant UUID'leri almak için:
--    SELECT id, owner_name FROM users WHERE role = 'merchant';
--
-- 2. Mapping kontrolü:
--    SELECT * FROM onlog_merchant_mapping WHERE is_active = true;
--
-- 3. Restoran pasif hale getirme:
--    UPDATE onlog_merchant_mapping SET is_active = false 
--    WHERE yemek_app_restaurant_id = 'R-1234';
-- ======================================================================
