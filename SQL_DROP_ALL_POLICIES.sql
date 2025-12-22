-- ================================================================
-- ÖNCE TÜM POLİTİKALARI SİL
-- ================================================================

-- USERS tablosu - Tüm politikaları sil
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Allow all authenticated users to read" ON users;
DROP POLICY IF EXISTS "Allow users to update own profile or admin update all" ON users;
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Enable insert for authentication" ON users;

-- DELIVERY_REQUESTS tablosu
DROP POLICY IF EXISTS "Admins can view all delivery requests" ON delivery_requests;
DROP POLICY IF EXISTS "Allow authenticated users to read delivery_requests" ON delivery_requests;

-- ORDERS tablosu
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
DROP POLICY IF EXISTS "Allow authenticated users to read orders" ON orders;

-- Sonuç kontrol
SELECT 'Tüm politikalar silindi!' as message;
