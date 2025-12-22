-- Orders tablosu yapısını kontrol et
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'orders'
ORDER BY ordinal_position;

-- Son 5 siparişi göster
SELECT 
  id,
  merchant_id,
  customer_id,
  status,
  total_amount,
  payment_method,
  created_at,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'orders' AND column_name = 'courier_id'
    ) THEN 'courier_id kolonu VAR'
    ELSE 'courier_id kolonu YOK!'
  END as courier_id_status
FROM orders
ORDER BY created_at DESC
LIMIT 5;

-- Payment transactions'daki kurye ödemelerini kontrol et
SELECT 
  id,
  order_id,
  courier_id,
  amount,
  type,
  status,
  created_at
FROM payment_transactions
WHERE type = 'deliveryFee'
ORDER BY created_at DESC
LIMIT 10;
