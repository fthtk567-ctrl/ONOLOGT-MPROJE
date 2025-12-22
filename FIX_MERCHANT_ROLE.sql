-- Mevcut market kaydının role'ünü düzelt

-- 1. Problemi gör
SELECT id, email, role, business_name, business_type
FROM users
WHERE email = 'secmarket@test.com';

-- 2. Düzelt
UPDATE users
SET 
  role = 'merchant',
  business_type = 'market'
WHERE email = 'secmarket@test.com';

-- 3. Kontrol et
SELECT id, email, role, business_type, business_name, status
FROM users
WHERE email = 'secmarket@test.com';
