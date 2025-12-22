-- COURIER KAYIT RLS POLİTİKASI DÜZELTME
-- Dün aldığın "new row violates row-level security policy" hatasını çözer

-- Önce eski politikayı siliyoruz (varsa)
DROP POLICY IF EXISTS "Users can insert their own record during registration" ON users;

-- Yeni kullanıcı kayıt sırasında kendi kaydını oluşturabilir
CREATE POLICY "Users can insert their own record during registration"
ON users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Kullanıcı kendi kaydını okuyabilir (zaten vardır ama kontrol edelim)
DROP POLICY IF EXISTS "Users can read their own data" ON users;

CREATE POLICY "Users can read their own data"
ON users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Kullanıcı kendi kaydını güncelleyebilir (profil düzenleme için)
DROP POLICY IF EXISTS "Users can update their own data" ON users;

CREATE POLICY "Users can update their own data"
ON users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Admin tüm kayıtları görebilir
DROP POLICY IF EXISTS "Admins can view all users" ON users;

CREATE POLICY "Admins can view all users"
ON users
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  )
);

-- Admin tüm kayıtları güncelleyebilir (onay işlemleri için)
DROP POLICY IF EXISTS "Admins can update all users" ON users;

CREATE POLICY "Admins can update all users"
ON users
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  )
);

-- ✅ BAŞARILI: Artık courier kayıt işlemi çalışacak!
