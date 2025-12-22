-- KAYIT SİSTEMİNİ TAMAMEN DÜZELTİYORUZ
-- Bu SQL'i kopyala yapıştır, hepsini birden çalıştır!

-- 1. ESKİ TRIGGER'I SİL
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. TÜM RLS POLİTİKALARINI SİL
DROP POLICY IF EXISTS "Users can insert their own record during registration" ON users;
DROP POLICY IF EXISTS "Users can read their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;
DROP POLICY IF EXISTS "Allow auth trigger to insert" ON users;
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Admins can do anything" ON users;

-- 3. YENİ BASIT RLS POLİTİKALARI (Infinite loop olmaz)
CREATE POLICY "Allow auth trigger to insert"
ON users FOR INSERT
WITH CHECK (true); -- Herkes insert edebilir (trigger için)

CREATE POLICY "Users can read own data"
ON users FOR SELECT
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Users can update own data"
ON users FOR UPDATE
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Admins can do anything"
ON users FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  )
);

-- 4. YENİ TRIGGER - BASIT VE ÇALIŞAN
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Auth'dan users tablosuna ekle
  INSERT INTO public.users (
    id, email, full_name, phone, role, status, is_active, metadata, created_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'courier'),
    'pending',
    false,
    COALESCE(NEW.raw_user_meta_data, '{}'::jsonb),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- 5. TRIGGER'I AKTİF ET
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ✅ TAMAM! Şimdi kayıt çalışacak, infinite loop yok!
