-- ============================================
-- TEST COURIER KULLANICISI OLUŞTUR
-- ============================================

-- 1. Supabase Auth'da kullanıcı oluştur (manuel):
-- https://supabase.com/dashboard/project/oilldfyywtzybrmpyixx/auth/users
-- "Add User" → Email: courier@test.com, Password: 123456

-- 2. YA DA mevcut admin kullanıcısını courier yap:
UPDATE users
SET role = 'courier', status = 'approved'
WHERE email = 'admin@onlog.com';

-- 3. Kontrol et:
SELECT id, email, role, status
FROM users
WHERE role = 'courier';

-- 4. Courier type ekle (esnaf):
UPDATE users
SET metadata = '{"courier_type": "esnaf"}'::jsonb
WHERE email = 'admin@onlog.com' AND role = 'courier';

-- ============================================
-- LOGIN BİLGİLERİ:
-- Email: admin@onlog.com
-- Password: 123456
-- Role: courier (esnaf)
-- ============================================
