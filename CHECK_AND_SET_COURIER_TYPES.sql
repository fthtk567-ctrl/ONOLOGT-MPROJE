-- Kuryeleri kontrol et (name kolonu olmadan)
SELECT 
  id,
  email,
  role,
  courier_type,
  created_at
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- Courier_type NULL olanları freelance yap
UPDATE users 
SET courier_type = 'freelance' 
WHERE role = 'courier' AND courier_type IS NULL;

-- Tekrar kontrol
SELECT 
  id,
  email,
  role,
  courier_type
FROM users
WHERE role = 'courier';
