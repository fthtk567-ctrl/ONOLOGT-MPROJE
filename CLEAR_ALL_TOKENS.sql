-- HER İKİ HESABIN OTURUMUNU TEMİZLE VE TOKEN'LARI SİL

-- 1. Trolloji'nin token'ını temizle
UPDATE users
SET fcm_token = NULL,
    updated_at = NOW()
WHERE email = 'trolloji.ai@gmail.com';

-- 2. Courier'ın token'ını temizle
UPDATE users
SET fcm_token = NULL,
    updated_at = NOW()
WHERE email = 'courier@onlog.com';

-- Kontrol et
SELECT 
    id,
    email,
    full_name,
    fcm_token,
    updated_at
FROM users
WHERE email IN ('courier@onlog.com', 'trolloji.ai@gmail.com')
ORDER BY email;
