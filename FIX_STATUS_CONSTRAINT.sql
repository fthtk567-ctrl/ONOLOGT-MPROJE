-- ═══════════════════════════════════════════════════
-- ONLOG - STATUS CONSTRAINT GÜNCELLEMESİ
-- 'accepted' status'ünü valid_status constraint'ine ekle
-- ═══════════════════════════════════════════════════

-- 1️⃣ Mevcut constraint'i kontrol et
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name LIKE '%status%'
AND constraint_schema = 'public';

-- 2️⃣ Eski constraint'i kaldır
ALTER TABLE delivery_requests 
DROP CONSTRAINT IF EXISTS valid_status;

ALTER TABLE delivery_requests 
DROP CONSTRAINT IF EXISTS delivery_requests_status_check;

-- 3️⃣ Yeni constraint ekle (TÜM STATUS DEĞERLERİ)
ALTER TABLE delivery_requests
ADD CONSTRAINT valid_status CHECK (
  status IN (
    'pending',         -- Beklemede (kurye aranıyor)
    'assigned',        -- Atandı (kurye kabul etmedi)
    'accepted',        -- ✅ Kabul edildi (yeni eklendi!)
    'picked_up',       -- Toplandı
    'in_progress',     -- Yolda (alternatif)
    'delivered',       -- Teslim edildi
    'cancelled',       -- İptal edildi
    'rejected'         -- Reddedildi (alternatif)
  )
);

-- 4️⃣ Kontrol
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name = 'valid_status';

-- 5️⃣ Test: Status güncelleme
-- UPDATE delivery_requests 
-- SET status = 'accepted' 
-- WHERE id = 'TEST_ID';

COMMENT ON CONSTRAINT valid_status ON delivery_requests IS 
'Geçerli teslimat durumları: pending, assigned, accepted, picked_up, in_progress, delivered, cancelled, rejected';
