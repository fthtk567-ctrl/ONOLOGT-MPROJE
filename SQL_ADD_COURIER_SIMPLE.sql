-- ============================================
-- MEVCUT COURIER KULLANICISINI EKLE (KOLAY YOL)
-- ============================================
-- Authentication'da zaten var, sadece users tablosuna ekleyeceğiz
-- UUID'yi Supabase Authentication'dan kopyala

-- ADIM 1: Supabase → Authentication → Users
-- courier2@test.com, courier1@test.com veya test@restorant.com'un UID'sini kopyala

-- ADIM 2: Aşağıdaki SQL'i düzenle - 'AUTH_USER_ID_BURAYA' yerine kopyaladığın UID'yi yapıştır
-- Örnek: '15ac7198-dc3a-493a-8d09-xxxxxxxxxxxx'

INSERT INTO users (
  id, 
  email, 
  role, 
  status,
  business_name,
  metadata,
  created_at,
  updated_at
) VALUES (
  '15ac7198-dc3a-493a-8d09-c44e27d6f0e9',  -- ← courier2@test.com'un UID'SI (Authentication'dan kopyala)
  'courier2@test.com',
  'courier',
  'approved',
  'Mehmet Kurye',
  '{"courier_type": "esnaf"}'::jsonb,
  NOW(),
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  role = 'courier',
  status = 'approved',
  business_name = 'Mehmet Kurye',
  metadata = '{"courier_type": "esnaf"}'::jsonb;

-- Kontrol et:
SELECT 
  id,
  email,
  role,
  status,
  business_name,
  metadata->>'courier_type' as courier_type
FROM users
WHERE email = 'courier2@test.com';

-- ============================================
-- LOGIN BİLGİLERİ (Courier App - http://localhost:5000):
-- Email: courier2@test.com
-- Password: (Authentication'da ayarlanmış şifre)
-- ============================================

-- ŞİFRE SIFIRLAMA (gerekirse):
-- Supabase → Authentication → Users → courier2@test.com → "Reset Password"
-- Ya da Login ekranında "Forgot Password" kullan
