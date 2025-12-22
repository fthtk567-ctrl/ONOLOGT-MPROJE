-- increment_courier_rejection FONKSIYONUNU OLUŞTUR
-- Kurye teslimatı reddettiğinde rejection_count'u artırır

CREATE OR REPLACE FUNCTION increment_courier_rejection(courier_id UUID)
RETURNS void AS $$
BEGIN
  -- users tablosunda rejection_count kolonunu +1 artır
  UPDATE users
  SET 
    rejection_count = COALESCE(rejection_count, 0) + 1,
    updated_at = NOW()
  WHERE id = courier_id;
  
  RAISE NOTICE 'Kurye % rejection_count artırıldı', courier_id;
END;
$$ LANGUAGE plpgsql;

-- Fonksiyonu test et (opsiyonel)
-- SELECT increment_courier_rejection('4ff777e0-5bcc-4c21-8785-c650f5667d86');

-- Kontrol: rejection_count kolonu var mı?
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name = 'rejection_count';

-- Eğer kolon yoksa ekle
ALTER TABLE users
ADD COLUMN IF NOT EXISTS rejection_count INTEGER DEFAULT 0;

-- Index ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_users_rejection_count ON users(rejection_count);

-- Test: Kuryelerin rejection_count'larını göster
SELECT 
  id,
  full_name,
  email,
  role,
  rejection_count,
  is_available
FROM users
WHERE role = 'courier'
ORDER BY rejection_count DESC NULLS LAST
LIMIT 5;
