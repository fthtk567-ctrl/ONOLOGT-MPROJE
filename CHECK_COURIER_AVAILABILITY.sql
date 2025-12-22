-- Fatih Teke'nin durumunu kontrol et
SELECT 
  id,
  full_name,
  email,
  role,
  is_available,
  is_active,
  status,
  fcm_token,
  last_login,
  current_location
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;
