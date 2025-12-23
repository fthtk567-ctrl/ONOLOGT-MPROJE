-- Webhook ve Trigger Loglarını Kontrol Et
-- Son sipariş: b0d81859-d407-40e6-b2ae-6190401db2ba (YO-025014)

-- 1. YO-025014 siparişi için Delivery Request oluştu mu?
SELECT 
  id,
  courier_id,
  merchant_id,
  merchant_name,
  declared_amount,
  status,
  external_order_id,
  source,
  created_at,
  assigned_at
FROM delivery_requests
WHERE external_order_id = 'YO-025014' OR id::text LIKE 'b0d81859%'
ORDER BY created_at DESC
LIMIT 3;

-- 2. Order bilgileri (orders tablosu varsa kontrol edelim)
-- NOT: Delivery_requests tablosu sipariş bilgilerini tutuyor olabilir

-- 3. Push token var mı? (Courier: 250f4abe-858a-457b-b972-9a76340b07c2)
SELECT 
  player_id,
  platform,
  created_at
FROM push_tokens
WHERE user_id = '250f4abe-858a-457b-b972-9a76340b07c2'
ORDER BY created_at DESC
LIMIT 3;

-- 4. Son webhook logları - NOT: webhook_logs tablosu yok
-- Webhook detayları delivery_requests.metadata içinde olabilir
