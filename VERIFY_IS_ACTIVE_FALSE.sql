-- Mevcut durumu kontrol et
SELECT 
  yemek_app_restaurant_id,
  onlog_merchant_id,
  restaurant_name,
  is_active,
  created_at,
  updated_at
FROM onlog_merchant_mapping
WHERE yemek_app_restaurant_id = 'R-TEST-001';

-- Eğer hala true ise false yap
UPDATE onlog_merchant_mapping
SET 
  is_active = false,
  updated_at = NOW()
WHERE yemek_app_restaurant_id = 'R-TEST-001'
  AND is_active = true;

-- Sonucu tekrar kontrol et
SELECT 
  yemek_app_restaurant_id,
  restaurant_name,
  is_active
FROM onlog_merchant_mapping
WHERE yemek_app_restaurant_id = 'R-TEST-001';
