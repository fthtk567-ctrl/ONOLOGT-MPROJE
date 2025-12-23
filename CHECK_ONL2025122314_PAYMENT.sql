-- ONL2025122314 siparişinin ödeme detaylarını kontrol et
SELECT 
  id,
  order_number,
  merchant_name,
  declared_amount,
  payment_method,
  status,
  created_at,
  pickup_location,
  delivery_location
FROM delivery_requests 
WHERE order_number = 'ONL2025122314';
