-- Eski siparişlerin payment_method değerlerini düzelt (eğer Yemek App farklı isimler gönderiyorsa)
-- NOT: Bu SQL'i çalıştırmadan önce önce yeni bir test siparişi oluştur ve log'lara bak

-- Örnek: Eğer database'de şöyle kayıtlar varsa:
-- UPDATE delivery_requests 
-- SET payment_method = 'card' 
-- WHERE payment_method LIKE '%kart%' OR payment_method LIKE '%card%';

-- UPDATE delivery_requests 
-- SET payment_method = 'online' 
-- WHERE payment_method LIKE '%online%' OR payment_method LIKE '%ödendi%';

-- Şimdilik sadece kontrol et:
SELECT 
  payment_method,
  COUNT(*) as order_count,
  ARRAY_AGG(order_number ORDER BY created_at DESC) FILTER (WHERE created_at > NOW() - INTERVAL '7 days') as recent_orders
FROM delivery_requests
WHERE order_number LIKE 'ONL%' OR order_number LIKE 'YO-%'
GROUP BY payment_method
ORDER BY order_count DESC;
