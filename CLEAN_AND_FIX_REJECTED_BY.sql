-- 🔍 REJECTED_BY KOLONUNDAKİ GEÇERSİZ VERİLERİ KONTROL ET VE TEMİZLE

-- 1. Hangi değerler var kontrol et
SELECT 
  rejected_by,
  pg_typeof(rejected_by) as "Tip",
  COUNT(*) as "Adet"
FROM delivery_requests
WHERE rejected_by IS NOT NULL
GROUP BY rejected_by, pg_typeof(rejected_by)
ORDER BY COUNT(*) DESC;

-- 2. Geçersiz değerleri bul (UUID formatında olmayanlar)
SELECT 
  id,
  order_number,
  rejected_by,
  LENGTH(rejected_by::TEXT) as "Uzunluk"
FROM delivery_requests
WHERE rejected_by IS NOT NULL
  AND rejected_by::TEXT NOT LIKE '________-____-____-____-____________'  -- UUID formatı değil
LIMIT 10;

-- 3. TEMİZLEME: Geçersiz değerleri NULL yap
UPDATE delivery_requests
SET rejected_by = NULL
WHERE rejected_by IS NOT NULL
  AND rejected_by::TEXT NOT LIKE '________-____-____-____-____________';

-- 4. Kontrol: Temizlendi mi?
SELECT 
  COUNT(*) as "Toplam rejected_by Dolu",
  SUM(CASE 
    WHEN rejected_by::TEXT LIKE '________-____-____-____-____________' THEN 1 
    ELSE 0 
  END) as "UUID Formatında Olanlar",
  SUM(CASE 
    WHEN rejected_by::TEXT NOT LIKE '________-____-____-____-____________' THEN 1 
    ELSE 0 
  END) as "Geçersiz Formatlar (Olmamalı!)"
FROM delivery_requests
WHERE rejected_by IS NOT NULL;

-- =====================================================
-- TEMİZLEME SONRASI: UUID'YE ÇEVİR
-- =====================================================

-- 5. Artık UUID'ye çevirebiliriz
ALTER TABLE delivery_requests 
ALTER COLUMN rejected_by TYPE UUID 
USING (rejected_by::TEXT)::UUID;

-- 6. Başarılı mı kontrol et
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
  AND column_name = 'rejected_by';

-- ✅ data_type = 'uuid' olmalı!
