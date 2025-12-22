-- Orders tablosuna courier_id kolonu ekle
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS courier_id UUID REFERENCES auth.users(id);

-- Index ekle
CREATE INDEX IF NOT EXISTS idx_orders_courier ON orders(courier_id);

-- Test et
SELECT 
  COUNT(*) as total_orders,
  COUNT(courier_id) as orders_with_courier
FROM orders;
