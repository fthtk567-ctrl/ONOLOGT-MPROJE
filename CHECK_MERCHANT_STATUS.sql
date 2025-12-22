-- Merchant'ın durumunu kontrol et

SELECT 
  id, 
  email, 
  role,
  status, 
  is_active,
  business_name,
  updated_at
FROM users
WHERE email = 'secmarket@test.com';
