-- ======================================================================
-- MERCHANT REGISTER TEST - YENİ RESTORAN KAYDI
-- ======================================================================
-- yemek-app-merchant-register Edge Function'ını test et
-- ======================================================================

-- Test için: Yeni restoran kaydı simüle et

-- 1. Test için mevcut mapping kontrolü
SELECT 
  yemek_app_restaurant_id,
  onlog_merchant_id,
  restaurant_name,
  is_active
FROM onlog_merchant_mapping
WHERE yemek_app_restaurant_id = 'TEST-R-12345';

-- 2. Test merchant varsa sil (temizlik)
DO $$
DECLARE
  v_merchant_id UUID;
BEGIN
  SELECT onlog_merchant_id INTO v_merchant_id
  FROM onlog_merchant_mapping
  WHERE yemek_app_restaurant_id = 'TEST-R-12345';
  
  IF v_merchant_id IS NOT NULL THEN
    DELETE FROM onlog_merchant_mapping WHERE yemek_app_restaurant_id = 'TEST-R-12345';
    DELETE FROM users WHERE id = v_merchant_id;
    RAISE NOTICE 'Test merchant cleaned up: %', v_merchant_id;
  END IF;
END $$;

-- ======================================================================
-- POWERSHELL TEST KOMUTU (Edge Function'a istek gönder)
-- ======================================================================

-- Copy-paste bu komutu PowerShell'e:

<#
$body = @{
  restaurant_id = "TEST-R-12345"
  restaurant_name = "Pizza Palace Test"
  phone = "+905321234567"
  email = "test@pizzapalace.com"
  address = @{
    full_address = "Kadıköy Moda, İstanbul"
    latitude = 40.9888
    longitude = 29.0320
  }
} | ConvertTo-Json

$headers = @{
  "Content-Type" = "application/json"
  "Authorization" = "Bearer TEST_API_KEY_BURAYA"
}

$response = Invoke-RestMethod -Uri "https://o11ldfywtzbrmpy1xx.supabase.co/functions/v1/yemek-app-merchant-register" -Method POST -Body $body -Headers $headers
$response | ConvertTo-Json -Depth 10
#>

-- ======================================================================
-- TEST SONRASI DOĞRULAMA
-- ======================================================================

-- 3. Yeni oluşturulan merchant'ı kontrol et
SELECT 
  id,
  business_name,
  business_phone,
  email,
  source,
  is_auto_registered,
  status,
  ST_AsText(business_location) as location_wkt,
  created_at
FROM users
WHERE source = 'yemek_app' 
  AND business_name = 'Pizza Palace Test'
ORDER BY created_at DESC
LIMIT 1;

-- 4. Mapping kaydını kontrol et
SELECT 
  yemek_app_restaurant_id,
  onlog_merchant_id,
  restaurant_name,
  is_active,
  created_at
FROM onlog_merchant_mapping
WHERE yemek_app_restaurant_id = 'TEST-R-12345';

-- 5. Merchant ID'yi al (sipariş testi için)
SELECT 
  m.onlog_merchant_id,
  u.business_name,
  u.email,
  u.is_auto_registered
FROM onlog_merchant_mapping m
JOIN users u ON u.id = m.onlog_merchant_id
WHERE m.yemek_app_restaurant_id = 'TEST-R-12345';

-- ✅ Test başarılı ise:
-- - users tablosunda yeni merchant kaydı var
-- - source = 'yemek_app'
-- - is_auto_registered = true
-- - onlog_merchant_mapping'de eşleşme var
