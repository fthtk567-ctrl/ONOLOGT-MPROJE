-- Yeni kaydolan eczane@test.com kullanıcısının verilerini kontrol et

SELECT 
  email,
  business_name,
  address,
  current_location,
  business_address,
  city,
  district,
  created_at
FROM users
WHERE email = 'eczane@test.com';

-- BEKLENEN:
-- current_location: {"latitude": 37.5670816, "longitude": 32.7882221}
-- address: Alparslan Türkeş Caddesi, Çaybaşı Mahallesi, Çumra
--
-- Eğer farklı koordinatlar varsa (37.8667, 32.4833) kayıt SONRASI bir şey konumu değiştiriyor!
