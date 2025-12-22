-- secmarket@test.com kullanıcısının mevcut konumunu kontrol et

SELECT 
  id,
  email,
  business_name,
  address,  -- Kayıt sırasında girdiğin adres metni
  current_location,  -- Harita ile seçtiğin koordinatlar (JSON)
  business_address,  -- Ek adres bilgisi
  city,
  district
FROM users
WHERE email = 'secmarket@test.com';

-- SONUÇ: current_location {"latitude": 37.8667, "longitude": 32.4833} 
-- Bu koordinatlar Konya şehir merkezi (Meram genel bölgesi)
-- Ama senin işletmenin TAM konumu değil!

-- ÇÖZÜMLERİ:
-- 1. Merchant Panel'de "Ayarlar" > "Konum Güncelle" (eğer varsa)
-- 2. Yeni merchant kaydı yap, haritadan TAM konum seç
-- 3. Bu SQL ile manuel güncelle (ama tam koordinatları sen ver)
