-- delivery_requests TABLOSUNA rejection_reason KOLONU EKLE
-- Kurye teslimatı reddettiğinde sebep kaydedilecek

ALTER TABLE delivery_requests
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Mevcut rejected durumundaki kayıtlar için default değer
UPDATE delivery_requests
SET rejection_reason = 'Belirtilmemiş'
WHERE status = 'rejected' 
  AND rejection_reason IS NULL;

-- Kontrol et
SELECT 
  id, 
  status, 
  rejected_by,
  rejection_reason,
  created_at
FROM delivery_requests
WHERE status = 'rejected' OR rejected_by IS NOT NULL
ORDER BY created_at DESC
LIMIT 5;

-- Eğer hiç rejected kayıt yoksa son 3 kaydı göster
SELECT 
  id, 
  status, 
  courier_id,
  created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 3;
