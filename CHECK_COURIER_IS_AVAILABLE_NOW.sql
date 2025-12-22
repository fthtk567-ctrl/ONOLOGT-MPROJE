-- Şu anda TROLLOJI KURYE'nin is_available durumunu kontrol et

SELECT 
  id,
  full_name,
  email,
  role,
  is_available,
  status,
  current_location,
  updated_at,
  fcm_token
FROM users
WHERE email = 'trolloji.ai@gmail.com'
  AND role = 'courier';

-- Tüm kuryelerin durumunu kontrol et
SELECT 
  full_name,
  email,
  is_available,
  status,
  CASE 
    WHEN is_available = true THEN '🟢 ÇEVRİMİÇİ'
    ELSE '🔴 ÇEVRİMDIŞI'
  END as durum
FROM users
WHERE role = 'courier'
ORDER BY is_available DESC, full_name;
