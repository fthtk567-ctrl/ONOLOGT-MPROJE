-- Yeni merchant başvurusunu manuel onayla
UPDATE users
SET 
  is_active = true,
  status = 'approved',
  updated_at = NOW()
WHERE email = 'onlogprojects@gmail.com'
  AND role = 'merchant';

-- Kontrol et
SELECT 
  id,
  email,
  business_name,
  role,
  status,
  is_active,
  created_at
FROM users
WHERE email = 'onlogprojects@gmail.com';
