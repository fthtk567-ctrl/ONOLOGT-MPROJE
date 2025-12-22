-- SORUN: Kayıt sırasında auth.uid() henüz NULL, bu yüzden INSERT başarısız
-- ÇÖZÜM: Kayıt için özel bir policy ekle

-- 1. Tüm sorunlu policy'leri kaldır
DROP POLICY IF EXISTS "Herkes kendi kaydını oluşturabilir" ON users;
DROP POLICY IF EXISTS "Enable insert for registration" ON users;
DROP POLICY IF EXISTS "Allow registration with auth id" ON users;

-- 2. YENİ: Kayıt için özel policy
-- signUp sırasında auth.uid() henüz NULL olabilir, ama id parametresi geliyor
CREATE POLICY "Enable insert for registration"
ON users
FOR INSERT
WITH CHECK (
  -- İlk kayıt: auth.uid() NULL ama id veriliyor
  (auth.uid() IS NULL AND id IS NOT NULL)
  OR
  -- Normal durum: auth.uid() varsa ve id ile eşleşiyorsa
  (auth.uid() = id)
  OR
  -- Trigger'dan gelen INSERT'ler için
  (current_user = 'postgres')
);

-- 3. Kontrol et
SELECT 
    policyname,
    cmd,
    with_check
FROM pg_policies
WHERE tablename = 'users'
AND cmd = 'INSERT'
ORDER BY policyname;
