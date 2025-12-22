-- UPSERT için hem INSERT hem UPDATE policy gerekli!
-- Şu anda sadece INSERT policy var, UPDATE eksik

-- 1. UPDATE policy'si ekle (UPSERT için gerekli)
DROP POLICY IF EXISTS "Enable update for registration" ON users;

CREATE POLICY "Enable update for registration"
ON users
FOR UPDATE
USING (
  -- Kendi kaydını güncelleyebilir
  auth.uid() = id
  OR
  -- Veya henüz auth context yoksa (kayıt sırasında)
  auth.uid() IS NULL
)
WITH CHECK (
  -- Kendi kaydını güncelleyebilir
  auth.uid() = id
  OR
  -- Veya henüz auth context yoksa
  auth.uid() IS NULL
);

-- 2. Kontrol et
SELECT 
    policyname,
    cmd,
    permissive,
    qual as using_expression,
    with_check
FROM pg_policies
WHERE tablename = 'users'
AND cmd IN ('INSERT', 'UPDATE')
ORDER BY cmd, policyname;
