-- ============================================
-- ADMIN KULLANICISINI PUBLIC.USERS TABLOSUNA EKLE
-- ============================================

-- Admin kullanıcısının UUID'sini al (Authentication'dan)
-- UUID: be32dfe4-5e27-4eba-8fd4-d9a2863dd184

-- Public.users tablosuna ekle
INSERT INTO public.users (
  id,
  email,
  full_name,
  phone,
  role,
  status,
  is_active,
  created_at,
  updated_at
) VALUES (
  'be32dfe4-5e27-4eba-8fd4-d9a2863dd184',
  'admin@onlog.com',
  'Admin User',
  NULL,
  'superAdmin',
  'approved',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  role = 'superAdmin',
  status = 'approved',
  is_active = true,
  updated_at = NOW();

-- Kontrol et
SELECT id, email, role, status, is_active
FROM users
WHERE email = 'admin@onlog.com';

-- ============================================
-- YA DA courier olarak ekle:
-- ============================================

UPDATE users
SET 
  role = 'courier',
  status = 'approved',
  is_active = true,
  metadata = jsonb_build_object(
    'courier_type', 'esnaf',
    'vehicle_type', 'motor'
  )
WHERE id = 'be32dfe4-5e27-4eba-8fd4-d9a2863dd184';

-- Son kontrol
SELECT id, email, role, status, metadata
FROM users
WHERE email = 'admin@onlog.com';
