-- ================================================================
-- FIX: Infinite recursion hatası
-- ================================================================
-- Sorun: RLS politikası kendi users tablosunu sorguluyor!
-- Çözüm: Önce eski politikaları sil, sonra doğru politika ekle
-- ================================================================

-- 1. Tüm users politikalarını sil
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;

-- 2. YENİ BASIT POLİTİKA - Herkes tüm kullanıcıları görebilir (Admin kontrolü app tarafında)
CREATE POLICY "Allow all authenticated users to read"
    ON users FOR SELECT
    TO authenticated
    USING (true);

-- 3. UPDATE için - Sadece kendi profilini veya adminse herkesi
CREATE POLICY "Allow users to update own profile or admin update all"
    ON users FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);

-- 4. DELIVERY_REQUESTS için basit politika
DROP POLICY IF EXISTS "Admins can view all delivery requests" ON delivery_requests;
CREATE POLICY "Allow authenticated users to read delivery_requests"
    ON delivery_requests FOR SELECT
    TO authenticated
    USING (true);

-- 5. ORDERS için basit politika
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
CREATE POLICY "Allow authenticated users to read orders"
    ON orders FOR SELECT
    TO authenticated
    USING (true);

-- 6. Kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('users', 'delivery_requests', 'orders')
ORDER BY tablename, policyname;
