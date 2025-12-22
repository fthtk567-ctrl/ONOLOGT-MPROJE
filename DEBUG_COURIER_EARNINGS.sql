-- 1. Test kuryesinin ID'sini al
SELECT id, email, courier_type FROM users WHERE email = 'courier@onlog.com';

-- 2. Bu kurye için payment_transactions var mı?
SELECT 
  pt.id,
  pt.type,
  pt.amount,
  pt.courier_id,
  pt.status,
  pt.created_at,
  o.status as order_status
FROM payment_transactions pt
LEFT JOIN orders o ON pt.order_id = o.id
WHERE pt.courier_id = '250f4abe-858a-457b-b972-9a76340b07c2'
ORDER BY pt.created_at DESC;

-- 3. Bu kurye atanmış siparişler var mı?
SELECT 
  id,
  status,
  courier_id,
  delivery_fee,
  total_amount,
  created_at
FROM orders
WHERE courier_id = '250f4abe-858a-457b-b972-9a76340b07c2'
ORDER BY created_at DESC
LIMIT 10;

-- 4. DELIVERED siparişler var mı?
SELECT COUNT(*) as delivered_orders
FROM orders
WHERE courier_id = '250f4abe-858a-457b-b972-9a76340b07c2'
  AND status = 'DELIVERED';
