-- assigned_at'i düzelt ve kurye bilgilendirilsin
UPDATE delivery_requests 
SET assigned_at = NOW()
WHERE external_order_id = 'YO-936727'
  AND assigned_at IS NULL;

-- Kontrol et
SELECT 
  external_order_id,
  status,
  courier_id,
  assigned_at,
  created_at
FROM delivery_requests 
WHERE external_order_id = 'YO-936727';
