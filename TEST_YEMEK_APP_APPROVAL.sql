-- Mevcut Yemek App bağlantı kayıtlarını kontrol et
SELECT 
  id,
  yemek_app_restaurant_id,
  onlog_merchant_id,
  restaurant_name,
  is_active,
  created_at,
  updated_at
FROM onlog_merchant_mapping
ORDER BY created_at DESC;

-- Test senaryosu için is_active'i false'a çek (bekleyen durum)
UPDATE onlog_merchant_mapping
SET is_active = false
WHERE yemek_app_restaurant_id = 'R-TEST-001';

-- Sonucu kontrol et
SELECT 
  yemek_app_restaurant_id,
  restaurant_name,
  is_active,
  onlog_merchant_id
FROM onlog_merchant_mapping
WHERE yemek_app_restaurant_id = 'R-TEST-001';
