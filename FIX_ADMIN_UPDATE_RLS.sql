-- Admin'in UPDATE yapabilmesi için RLS politikası

-- 1. Mevcut UPDATE politikalarını gör
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'users' AND cmd = 'UPDATE';

-- 2. Admin için UPDATE politikası ekle
DROP POLICY IF EXISTS "Admins can update all users" ON users;

CREATE POLICY "Admins can update all users"
ON users
FOR UPDATE
TO authenticated
USING (
  -- Admin veya superAdmin ise herşeyi güncelleyebilir
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role IN ('admin', 'superAdmin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role IN ('admin', 'superAdmin')
  )
);

-- 3. Politikaları kontrol et
SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'users' AND cmd = 'UPDATE';
