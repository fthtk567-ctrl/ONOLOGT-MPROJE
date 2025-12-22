-- Merchant Kayıt RLS Politikası Düzeltmesi
-- Yeni merchant'ların kendilerini kaydedebilmesini sağla

-- 1. Mevcut INSERT politikalarını kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'users' AND cmd = 'INSERT';

-- 2. Public INSERT politikası ekle (kayıt için gerekli)
DROP POLICY IF EXISTS "Herkes kendi kaydını oluşturabilir" ON users;

CREATE POLICY "Herkes kendi kaydını oluşturabilir"
ON users
FOR INSERT
TO public
WITH CHECK (
  auth.uid() = id  -- Sadece kendi ID'sine kayıt yapabilir
);

-- 3. Alternatif: Daha esnek politika (önerilir)
DROP POLICY IF EXISTS "Authenticated users can insert their own record" ON users;

CREATE POLICY "Authenticated users can insert their own record"
ON users
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = id
);

-- 4. Politikaları kontrol et
SELECT * FROM pg_policies WHERE tablename = 'users';
