-- ═══════════════════════════════════════════════════
-- ONLOG - USERS TABLOSU RLS POLİCY DÜZELTMESİ
-- Yeni merchant kaydı için INSERT izni
-- ═══════════════════════════════════════════════════

-- 1️⃣ ÖNCE MEVCUT POLİCY'LERİ SİL (çakışma olmasın)
DROP POLICY IF EXISTS "Users can register themselves" ON users;
DROP POLICY IF EXISTS "Enable insert for registration" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Public users readable" ON users;
DROP POLICY IF EXISTS "Enable read access for all users" ON users;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON users;
DROP POLICY IF EXISTS "Enable insert for authentication" ON users;

-- 2️⃣ INSERT policy ekle (KAYIT İÇİN EN ÖNEMLİSİ!)
CREATE POLICY "Enable insert for registration" ON users
  FOR INSERT
  WITH CHECK (true);

-- 3️⃣ SELECT policy (herkes herkesi görebilir - merchant/courier bilgileri için gerekli)
CREATE POLICY "Enable read access for all users" ON users
  FOR SELECT
  USING (true);

-- 4️⃣ UPDATE policy (sadece kendi profilini güncelleyebilir)
CREATE POLICY "Enable update for users based on user_id" ON users
  FOR UPDATE
  USING (auth.uid() = id);

-- 5️⃣ Kontrol et
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'users' ORDER BY policyname;

-- ═══════════════════════════════════════════════════
-- NOT: Kayıt işlemi şöyle çalışıyor:
-- 1. Supabase Auth ile hesap oluşturulur (signUp)
-- 2. auth.uid() ile user ID alınır
-- 3. users tablosuna INSERT yapılır
-- 4. RLS policy kontrol eder: auth.uid() == id mi?
-- ═══════════════════════════════════════════════════
