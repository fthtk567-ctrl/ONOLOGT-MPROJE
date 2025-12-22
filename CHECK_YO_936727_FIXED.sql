-- YO-936727 siparişini kontrol et (DOĞRU COLUMN ADLARI)
SELECT 
  id,
  external_order_id,
  status,
  courier_id,
  source,
  merchant_name,
  merchant_phone,
  recipient_name,
  recipient_phone,
  pickup_location,
  delivery_location,
  declared_amount,
  payment_method,
  rejection_count,
  rejection_reason,
  created_at,
  updated_at,
  assigned_at,
  accepted_at
FROM delivery_requests 
WHERE external_order_id = 'YO-936727';

-- Müsait kuryeler var mı?
SELECT 
  id,
  owner_name,
  phone,
  is_available,
  courier_type
FROM users
WHERE role = 'courier' 
  AND is_available = true
LIMIT 10;
