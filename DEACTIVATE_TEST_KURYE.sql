-- TEST KURYE hesabını deaktif et
-- Böylece yeni teslimat isteklerinde bu kuryeye atama yapılmayacak

UPDATE users
SET is_active = false
WHERE email = 'fatihteke@test.com'  -- TEST KURYE
  AND role = 'courier';

-- Kontrol et
SELECT 
    email,
    full_name,
    owner_name,
    is_active,
    status,
    is_available
FROM users
WHERE role = 'courier'
ORDER BY is_active DESC, email;
