-- Merchant kullanıcısının konum bilgilerini kontrol et
SELECT 
    id,
    email,
    business_name,
    business_address,
    address,
    city,
    district,
    phone,
    business_phone,
    current_location
FROM users 
WHERE role = 'merchant'
AND email = 'merchantt@test.com';

-- ✅ Çumra/Konya koordinatlarını JSON formatında ekle
UPDATE users 
SET 
  current_location = '{"latitude": 37.57, "longitude": 32.79}'::jsonb,
  address = COALESCE(address, business_address, 'Çumra/Konya'),
  city = COALESCE(city, 'Konya'),
  district = COALESCE(district, 'Çumra')
WHERE email = 'merchantt@test.com';

-- Kontrol et
SELECT 
    business_name,
    business_address,
    address,
    city,
    district,
    current_location
FROM users 
WHERE email = 'merchantt@test.com';

