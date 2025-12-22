-- INFINITE RECURSION'U TAMAMEN KALDIRIYORUZ!

-- Önce tüm politikaları sil
DROP POLICY IF EXISTS "Allow auth trigger to insert" ON users;
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Admins can do anything" ON users;
DROP POLICY IF EXISTS "Allow insert from trigger" ON users;
DROP POLICY IF EXISTS "Read own user" ON users;
DROP POLICY IF EXISTS "Update own user" ON users;
DROP POLICY IF EXISTS "Admin can delete" ON users;

-- YENİ POLİTİKALAR - INFINITE LOOP YOK!

-- 1. Insert - Sadece trigger için
CREATE POLICY "Allow insert from trigger"
ON users FOR INSERT
WITH CHECK (true);

-- 2. Select - Sadece kendi kaydını oku veya admin/superAdmin
CREATE POLICY "Read own user"
ON users FOR SELECT
TO authenticated
USING (auth.uid() = id OR auth.jwt()->>'role' IN ('admin', 'superAdmin'));

-- 3. Update - Sadece kendi kaydını güncelle veya admin/superAdmin
CREATE POLICY "Update own user"
ON users FOR UPDATE
TO authenticated
USING (auth.uid() = id OR auth.jwt()->>'role' IN ('admin', 'superAdmin'));

-- 4. Delete - Sadece admin/superAdmin
CREATE POLICY "Admin can delete"
ON users FOR DELETE
TO authenticated
USING (auth.jwt()->>'role' IN ('admin', 'superAdmin'));

-- ✅ TAMAM! Admin kontrolü JWT'den yapılıyor, infinite loop yok!
