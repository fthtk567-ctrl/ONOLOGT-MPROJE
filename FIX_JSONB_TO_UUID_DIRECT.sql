-- 🔧 JSONB'DEN UUID EXTRACT ET VE ÇEVİR

-- 1. Önce rejected_by'ın gerçek içeriğini görelim
SELECT 
  rejected_by,
  rejected_by::TEXT as "Text Hali",
  jsonb_typeof(rejected_by) as "JSONB Tipi"
FROM delivery_requests
WHERE rejected_by IS NOT NULL
LIMIT 3;

-- 2. JSONB ise içindeki UUID'yi çıkar
-- Eğer JSONB string ise:
SELECT 
  rejected_by,
  rejected_by #>> '{}' as "Extracted Value"
FROM delivery_requests
WHERE rejected_by IS NOT NULL
LIMIT 3;

-- 3. TEMİZLEME ve DÖNÜŞTÜRME (TEK SEFERDE)
ALTER TABLE delivery_requests 
ALTER COLUMN rejected_by TYPE UUID 
USING CASE
  WHEN rejected_by IS NULL THEN NULL
  WHEN jsonb_typeof(rejected_by) = 'string' THEN (rejected_by #>> '{}')::UUID
  ELSE NULL  -- Geçersiz formattaki verileri NULL yap
END;

-- 4. Başarı kontrolü
SELECT 
  column_name,
  data_type,
  'Artık UUID tipinde!' as "Durum"
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
  AND column_name = 'rejected_by';

-- 5. Test sorgusu - artık çalışmalı
SELECT 
  order_number,
  courier_id,
  rejected_by,
  CASE 
    WHEN courier_id = rejected_by THEN '❌ AYNI'
    WHEN rejected_by IS NOT NULL THEN '✅ FARKLI'
    ELSE '➖'
  END as "Kontrol"
FROM delivery_requests
WHERE rejected_by IS NOT NULL
LIMIT 5;
