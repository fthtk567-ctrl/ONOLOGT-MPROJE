-- 1. Orders tablosunda courier_id var mı?
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'orders'
  AND column_name = 'courier_id';

-- 2. Payment transactions'da kurye ödemesi var mı?
SELECT COUNT(*) as courier_payment_count
FROM payment_transactions
WHERE type = 'deliveryFee';

-- 3. Eğer varsa göster
SELECT pt.*, o.status as order_status
FROM payment_transactions pt
LEFT JOIN orders o ON pt.order_id = o.id
WHERE pt.type = 'deliveryFee'
LIMIT 5;

-- 4. Orders tablosunda courier atanmış siparişler var mı?
SELECT COUNT(*) as orders_with_courier
FROM orders
WHERE courier_id IS NOT NULL;
