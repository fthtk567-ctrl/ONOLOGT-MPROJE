-- Yeni merchant'ı onaylama SQL'i
-- En son kayıt olan merchant'ı bul ve onayla

-- 1. Son kayıt olan merchant'ı göster
SELECT id, email, business_name, status, created_at
FROM users
WHERE role = 'merchant'
ORDER BY created_at DESC
LIMIT 5;

-- 2. Onaylama - email adresini değiştir
UPDATE users
SET 
  status = 'approved',
  is_active = true,
  updated_at = NOW()
WHERE email = 'BURAYA_YENİ_MERCHANT_EMAİLİNİ_YAZ'  -- Örn: 'kerim@test.com'
  AND role = 'merchant';

-- 3. Kontrol et
SELECT id, email, business_name, status, is_active, current_location
FROM users
WHERE email = 'BURAYA_YENİ_MERCHANT_EMAİLİNİ_YAZ';
