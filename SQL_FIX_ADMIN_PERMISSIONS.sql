-- ================================================================
-- ADMIN PANEL İÇİN RLS POLİTİKALARINI DÜZELT
-- ================================================================
-- Sorun: Admin tüm kullanıcıları göremiyor!
-- Çözüm: Admin (superAdmin) rolüne tam yetki ver
-- ================================================================

-- 1. Önce mevcut politikaları kontrol et
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'users';

-- 2. USERS tablosu için Admin politikası ekle
DROP POLICY IF EXISTS "Admins can view all users" ON users;
CREATE POLICY "Admins can view all users"
    ON users FOR SELECT
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role IN ('admin', 'superAdmin')
        )
        OR auth.uid() = id
    );

-- 3. USERS tablosu için Admin update politikası
DROP POLICY IF EXISTS "Admins can update all users" ON users;
CREATE POLICY "Admins can update all users"
    ON users FOR UPDATE
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role IN ('admin', 'superAdmin')
        )
    );

-- 4. DELIVERY_REQUESTS için Admin politikası
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

-- 5. ORDERS için Admin politikası
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
CREATE POLICY "Admins can view all orders"
    ON orders FOR SELECT
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role IN ('admin', 'superAdmin')
        )
        OR auth.uid() = merchant_id
    );

-- 6. Tüm kullanıcıları listele (kontrol için)
SELECT 
    id,
    email,
    role,
    business_name,
    owner_name,
    full_name,
    status,
    is_active,
    created_at
FROM users
ORDER BY created_at DESC;

-- 7. Admin kullanıcısını kontrol et
SELECT id, email, role 
FROM users 
WHERE role IN ('admin', 'superAdmin');
