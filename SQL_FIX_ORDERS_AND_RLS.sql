-- ================================================================
-- FIX: Orders tablosuna merchant_id ekle
-- ================================================================

-- 1. Orders tablosuna merchant_id kolonu ekle
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS merchant_id UUID REFERENCES users(id);

-- 2. Delivery_requests tablosunu kontrol et
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'delivery_requests'
ORDER BY ordinal_position;

-- 3. Orders tablosunu kontrol et
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'orders'
ORDER BY ordinal_position;

-- 4. Şimdi RLS politikalarını ekle
-- USERS için
DROP POLICY IF EXISTS "Admins can view all users" ON users;
CREATE POLICY "Admins can view all users"
    ON users FOR SELECT
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role IN ('admin', 'superAdmin')
        )
        OR auth.uid() = id
    );

DROP POLICY IF EXISTS "Admins can update all users" ON users;
CREATE POLICY "Admins can update all users"
    ON users FOR UPDATE
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role IN ('admin', 'superAdmin')
        )
    );

-- DELIVERY_REQUESTS için
DROP POLICY IF EXISTS "Admins can view all delivery requests" ON delivery_requests;
CREATE POLICY "Admins can view all delivery requests"
    ON delivery_requests FOR SELECT
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role IN ('admin', 'superAdmin')
        )
        OR auth.uid() = merchant_id
        OR auth.uid() = courier_id
    );

-- ORDERS için (merchant_id opsiyonel olabilir)
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
CREATE POLICY "Admins can view all orders"
    ON orders FOR SELECT
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role IN ('admin', 'superAdmin')
        )
        OR (merchant_id IS NOT NULL AND auth.uid() = merchant_id)
    );
