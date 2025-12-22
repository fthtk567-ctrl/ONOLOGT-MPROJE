-- is_available column'ını users tablosuna ekle
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT FALSE;

-- Index ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_users_is_available ON users(is_available);

-- Mevcut courier'ları online yap (opsiyonel)
UPDATE users 
SET is_available = true 
WHERE role = 'courier' AND is_active = true;

COMMENT ON COLUMN users.is_available IS 'Kurye müsait mi? (online/offline durumu)';
