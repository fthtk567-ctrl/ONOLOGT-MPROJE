-- Users tablosuna herkesin kayıt yapabilmesi için policy ekle
-- Problem: Yeni kullanıcılar auth.uid() olmadan INSERT yapamıyor

-- 1. Önce mevcut INSERT policy'leri kaldır (varsa)
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON users;
DROP POLICY IF EXISTS "Users can insert own record" ON users;
DROP POLICY IF EXISTS "Allow public registration" ON users;

-- 2. YENİ POLICY: Herkes kendi ID'si ile kayıt yapabilir
-- Merchant/Courier kayıt sırasında auth.uid() henüz set olmamış olabilir
-- Bu yüzden id kolonu ile eşleşmeyi kontrol ediyoruz
CREATE POLICY "Allow registration with auth id"
ON users
FOR INSERT
WITH CHECK (
  -- Kullanıcı kendi auth ID'si ile kayıt yapabilir
  auth.uid() = id
  OR
  -- Veya henüz auth context yoksa (ilk kayıt sırasında)
  auth.uid() IS NULL
);

-- 3. VEYA daha basit: Service role ile bypass
-- Eğer yukarıdaki çalışmazsa, tüm INSERT'lere izin ver
-- DROP POLICY IF EXISTS "Allow registration with auth id" ON users;
-- CREATE POLICY "Allow all inserts during registration"
-- ON users
-- FOR INSERT
-- WITH CHECK (true);

-- 4. Kontrol et
SELECT 
    policyname,
    cmd,
    with_check
FROM pg_policies
WHERE tablename = 'users'
AND cmd = 'INSERT';
