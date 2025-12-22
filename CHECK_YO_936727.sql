-- YO-936727 siparişini bul ve detaylarını göster (düzeltilmiş)
SELECT 
  id,
  external_order_id,
  status,
  courier_id,
  source,
  delivery_address,
  declared_amount,
  payment_method,
  created_at,
  updated_at,
  rejection_count
FROM delivery_requests 
WHERE external_order_id = 'YO-936727';
