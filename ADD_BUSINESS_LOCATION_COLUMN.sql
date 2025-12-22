-- ═══════════════════════════════════════════════════
-- ONLOG - İŞLETME SABİT KONUM KOLONU EKLE
-- business_location: İşletmenin kayıt sırasında seçilen SABİT konumu
-- ═══════════════════════════════════════════════════

-- 1️⃣ business_location kolonu ekle (JSONB)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS business_location JSONB;

-- Format:
-- {
--   "latitude": 37.5671,
--   "longitude": 32.7882,
--   "address": "Eczane ABC, Konya"
-- }

-- 2️⃣ Mevcut merchant'lar için current_location'ı business_location'a kopyala
-- (Geçici çözüm - sonra düzgün kayıt ekranından girilecek)
UPDATE users
SET business_location = current_location
WHERE role = 'merchant' 
  AND current_location IS NOT NULL
  AND business_location IS NULL;

-- 3️⃣ Index ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_users_business_location 
ON users USING GIN (business_location);

-- 4️⃣ Kontrol et
SELECT 
  id,
  full_name,
  business_name,
  role,
  address,
  business_address,
  current_location,
  business_location
FROM users
WHERE role = 'merchant'
LIMIT 3;

-- 5️⃣ Açıklama
COMMENT ON COLUMN users.business_location IS 
'İşletmenin SABİT konumu (kayıt sırasında harita ile seçilen). 
current_location anlık GPS konumu, business_location taşınmaz işletme adresi.';

-- ═══════════════════════════════════════════════════
-- KULLANIM:
-- - Kurye çağırırken: business_location kullan
-- - Konum takibi için: current_location kullan
-- ═══════════════════════════════════════════════════
