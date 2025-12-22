-- ============================================
-- SON EKLENEN DELIVERY_REQUESTS KAYITLARINI KONTROL ET
-- ============================================

-- 1. Son 5 delivery_request kaydı
SELECT 
  id,
  merchant_id,
  status,
  source,
  external_order_id,
  declared_amount,
  created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 5;

-- 2. Yemek App'ten gelen siparişler
SELECT 
  id,
  merchant_id,
  status,
  external_order_id,
  declared_amount,
  created_at
FROM delivery_requests
WHERE source = 'yemek_app'
ORDER BY created_at DESC
LIMIT 5;

-- 3. Merchant'ın bilgileri (hangi merchant_id ile login yapıyorsun?)
SELECT 
  id,
  email,
  business_name,
  role
FROM users
WHERE role = 'merchant'
ORDER BY created_at DESC
LIMIT 5;
