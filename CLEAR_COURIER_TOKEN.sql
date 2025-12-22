-- courier@onlog.com hesabının FCM token'ını temizle

UPDATE users
SET fcm_token = NULL,
    updated_at = NOW()
WHERE email = 'courier@onlog.com';

-- Kontrol et
SELECT 
    id,
    email,
    full_name,
    role,
    fcm_token,
    created_at
FROM users
WHERE email IN ('courier@onlog.com', 'trolloji.a@gmail.com')
ORDER BY email;
