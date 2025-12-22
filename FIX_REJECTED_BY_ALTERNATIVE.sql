-- 🔧 ALTERNATİF: REJECTED_BY Kolonu NULL Değer İçeriyorsa

-- 1. Önce mevcut değerleri kontrol et
SELECT 
  COUNT(*) as "Toplam",
  COUNT(rejected_by) as "rejected_by Dolu",
  COUNT(*) - COUNT(rejected_by) as "rejected_by NULL"
FROM delivery_requests;

-- 2. Dolu olanların tipini kontrol et
SELECT 
  rejected_by,
  pg_typeof(rejected_by) as "Tip",
  jsonb_typeof(rejected_by) as "JSONB Alt Tipi"
FROM delivery_requests
WHERE rejected_by IS NOT NULL
LIMIT 5;

-- =====================================================
-- EĞER rejected_by İÇİNDE STRING FORMATINDA UUID VARSA:
-- =====================================================

-- 3a. Önce default'u kaldır
ALTER TABLE delivery_requests 
ALTER COLUMN rejected_by DROP DEFAULT;

-- 3b. UUID'ye dönüştür (NULL olanlar NULL kalacak)
ALTER TABLE delivery_requests 
ALTER COLUMN rejected_by TYPE UUID 
USING CASE 
  WHEN rejected_by IS NULL THEN NULL
  ELSE (rejected_by #>> '{}')::UUID  -- JSONB string'i UUID'ye çevir
END;

-- =====================================================
-- EĞER HATA VERİRSE: YENİ KOLON OLUŞTUR
-- =====================================================

-- 4. Alternatif: Yeni kolon oluştur ve veriyi kopyala
ALTER TABLE delivery_requests 
ADD COLUMN rejected_by_uuid UUID;

-- Veriyi kopyala
UPDATE delivery_requests 
SET rejected_by_uuid = (rejected_by #>> '{}')::UUID
WHERE rejected_by IS NOT NULL;

-- Eski kolonu sil
ALTER TABLE delivery_requests 
DROP COLUMN rejected_by;

-- Yeni kolonu rename et
ALTER TABLE delivery_requests 
RENAME COLUMN rejected_by_uuid TO rejected_by;

-- =====================================================
-- TEST
-- =====================================================

-- 5. Artık UUID karşılaştırması çalışmalı
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
