-- delivery_requests TABLOSUNA order_number KOLONU EKLE

ALTER TABLE delivery_requests
ADD COLUMN IF NOT EXISTS order_number VARCHAR(50);

-- Mevcut kayıtlar için otomatik order_number oluştur
UPDATE delivery_requests
SET order_number = 'ORD-' || id
WHERE order_number IS NULL;

-- Kontrol et
SELECT id, order_number, status, created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 5;
