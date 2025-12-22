-- SORUN: JWT'de role bilgisi yok! + Infinite recursion!
-- ÇÖZÜM: SECURITY DEFINER fonksiyon + Basit politikalar

-- Önce tüm politikaları sil
DROP POLICY IF EXISTS "Allow auth trigger to insert" ON users;
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Admins can do anything" ON users;
DROP POLICY IF EXISTS "Allow insert from trigger" ON users;
DROP POLICY IF EXISTS "Read own user" ON users;
DROP POLICY IF EXISTS "Update own user" ON users;
DROP POLICY IF EXISTS "Admin can delete" ON users;

-- Fonksiyon: Kullanıcının admin olup olmadığını kontrol et (RLS bypass)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER -- RLS'i bypass eder
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role IN ('admin', 'superAdmin')
  );
END;
$$;

-- YENİ POLİTİKALAR - Fonksiyon kullanarak!

-- 1. Insert - Sadece trigger için
CREATE POLICY "Allow insert from trigger"
ON users FOR INSERT
WITH CHECK (true);

-- 2. Select - Kendi kaydını oku VEYA admin ise tüm kayıtları görebilir
CREATE POLICY "Read own user"
ON users FOR SELECT
TO authenticated
USING (auth.uid() = id OR is_admin());

-- 3. Update - Kendi kaydını güncelle VEYA admin tüm kayıtları güncelleyebilir
CREATE POLICY "Update own user"
ON users FOR UPDATE
TO authenticated
USING (auth.uid() = id OR is_admin());

-- 4. Delete - Sadece admin
CREATE POLICY "Admin can delete"
ON users FOR DELETE
TO authenticated
USING (is_admin());

-- ✅ TAMAM! SECURITY DEFINER fonksiyon RLS'i bypass ediyor, infinite loop yok!
