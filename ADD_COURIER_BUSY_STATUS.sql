-- Kurye meşguliyet durumu için alan ekle

-- 1. Yeni kolon ekle
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_busy BOOLEAN DEFAULT FALSE;

-- 2. Açıklama ekle
COMMENT ON COLUMN users.is_busy IS 'Kurye şu anda paket taşıyor mu? true=meşgul, false=müsait';

-- 3. İndeks ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_courier_availability 
ON users(role, is_available, is_active, is_busy) 
WHERE role = 'courier';

-- 4. Mevcut kuryeleri güncelle (hepsi müsait başlasın)
UPDATE users 
SET is_busy = FALSE 
WHERE role = 'courier';

-- 5. Kontrol et
SELECT 
    email,
    full_name,
    is_available as "Mesaide mi?",
    is_busy as "Paket taşıyor mu?",
    is_active as "Aktif mi?"
FROM users
WHERE role = 'courier'
ORDER BY email;
