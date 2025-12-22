-- Admin kullanıcı kontrol ve oluşturma sorguları

-- 1. Mevcut admin kullanıcılarını kontrol et
SELECT id, email, role, status, is_active, created_at 
FROM users 
WHERE role IN ('admin', 'superAdmin') 
ORDER BY created_at DESC;

-- 2. Eğer admin yoksa, admin kullanıcı oluştur (manuel olarak)
-- Bu SQL'i Supabase Dashboard'da çalıştırın:
/*
INSERT INTO users (
  id, 
  email, 
  role, 
  status, 
  is_active,
  full_name,
  phone,
  created_at,
  updated_at
) 
VALUES (
  gen_random_uuid(),
  'admin@onlog.com.tr',
  'superAdmin',
  'approved',
  true,
  'System Administrator',
  '+90 555 000 00 00',
  now(),
  now()
);
*/

-- 3. Admin için Supabase Auth kullanıcısı oluşturmak için gerekli bilgi
-- Supabase Dashboard > Authentication > Users > Invite user
-- Email: admin@onlog.com.tr
-- Geçici şifre: AdminOnlog2024!

-- 4. Kontrol et
SELECT id, email, role, status, is_active 
FROM users 
WHERE email = 'admin@onlog.com.tr';

-- 5. Tüm admin/superAdmin rollerini listele
SELECT 
    u.email, 
    u.role, 
    u.status, 
    u.is_active,
    u.full_name,
    u.created_at
FROM users u 
WHERE u.role IN ('admin', 'superAdmin')
ORDER BY u.created_at DESC;