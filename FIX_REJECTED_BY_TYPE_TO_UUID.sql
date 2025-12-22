-- 🔧 REJECTED_BY KOLONUNU JSONB'DEN UUID'YE ÇEVİR
-- Sorun: rejected_by kolonu JSONB tipinde, UUID olmalı

-- 1. Önce default değeri kaldır
ALTER TABLE delivery_requests 
ALTER COLUMN rejected_by DROP DEFAULT;

-- 2. Şimdi UUID'ye çevir
ALTER TABLE delivery_requests 
ALTER COLUMN rejected_by TYPE UUID 
USING (rejected_by::TEXT)::UUID;

-- 3. Kontrol et - artık UUID olmalı
SELECT 
  column_name,
  data_type,
  pg_typeof(rejected_by) as "Gerçek Tip"
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
  AND column_name = 'rejected_by';

-- 4. Test sorgusu - artık çalışmalı
SELECT 
  dr.order_number,
  dr.courier_id,
  dr.rejected_by,
  CASE 
    WHEN dr.courier_id = dr.rejected_by THEN '❌ AYNI!'
    WHEN dr.rejected_by IS NOT NULL AND dr.courier_id != dr.rejected_by THEN '✅ FARKLI'
    ELSE '➖'
  END as "Kontrol"
FROM delivery_requests dr
WHERE dr.rejected_by IS NOT NULL
LIMIT 5;

-- ✅ Bu SQL'i sırayla çalıştır:
-- 1. DROP DEFAULT
-- 2. ALTER TYPE
-- 3. Kontrol
-- 4. Test
