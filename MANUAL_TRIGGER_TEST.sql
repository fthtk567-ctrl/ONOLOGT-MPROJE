-- ============================================
-- MANUEL TRİGGER TEST - UPDATE SİMÜLE ET
-- ============================================

-- 1. Yeni bir test teslimati oluştur
INSERT INTO delivery_requests (
  id,
  merchant_id,
  pickup_address,
  delivery_address,
  declared_amount,
  status,
  courier_id
) VALUES (
  gen_random_uuid(),
  '52f6ae11-b53c-402d-8fc7-1784cf43ab15', -- Merchant ID (senin merchant'ın)
  'Test Pickup Address',
  'Test Delivery Address',
  50.00,
  'assigned',
  '250f4abe-858a-457b-b972-9a76340b07c2' -- Courier ID
)
RETURNING id, courier_id, status;

-- Bu INSERT trigger'ı tetikledi mi kontrol et!
-- Sonra Courier App'te bildirim geldi mi bak!
