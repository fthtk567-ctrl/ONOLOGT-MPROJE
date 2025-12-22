-- Son kayıtları kontrol et
SELECT 
  id,
  email,
  role,
  full_name,
  status,
  is_active,
  created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- Bekleyen başvuruları kontrol et
SELECT 
  id,
  email,
  role,
  status,
  created_at
FROM users
WHERE status = 'pending'
ORDER BY created_at DESC;

-- Onaylanan kuryerleri kontrol et
SELECT 
  id,
  email,
  role,
  full_name,
  status,
  is_active,
  created_at
FROM users
WHERE role = 'courier' AND status = 'approved'
ORDER BY created_at DESC;

-- Email duplicate kontrolü
SELECT email, COUNT(*) as count
FROM users
WHERE email IN ('test5@deneme.com', 'test6@deneme.com')
GROUP BY email;
