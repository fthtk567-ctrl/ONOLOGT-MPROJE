-- Merchant konumlarını kontrol et

SELECT 
  id,
  business_name,
  business_location,
  current_location,
  address,
  city
FROM users
WHERE role = 'merchant'
ORDER BY created_at DESC
LIMIT 5;

-- business_location NULL ise haritadan konum seçilmemiş demektir
