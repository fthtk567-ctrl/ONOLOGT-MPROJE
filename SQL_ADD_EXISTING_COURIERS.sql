-- ============================================
-- AUTH'DAKI COURIER KULLANICILARINI USERS TABLOSUNA EKLE
-- ============================================

-- 1. courier2@test.com (Mehmet Kurye)
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
  '15ac7198-dc3a-493a-8d09-c1234567890a', -- UUID'yi tam yaz
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

-- 2. courier1@test.com (Ahmet Kurye)
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
  '914d391c-743d-452a-9b09-c1234567890b', -- UUID'yi tam yaz
  'courier1@test.com',
  'courier',
  'approved',
  'Ahmet Kurye',
  '{"courier_type": "esnaf"}'::jsonb,
  NOW(),
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  role = 'courier',
  status = 'approved',
  business_name = 'Ahmet Kurye',
  metadata = '{"courier_type": "esnaf"}'::jsonb;

-- 3. test@restorant.com (tesy/abc)
INSERT INTO users (
  id, 
  email, 
  role, 
  status,
  business_name,
  owner_name,
  metadata,
  created_at,
  updated_at
) VALUES (
  '7b6e981d-4d0a-4016-89fe-de184590226f', -- UUID'yi tam yaz
  'test@restorant.com',
  'courier',
  'approved',
  'tesy',
  'abc',
  '{"courier_type": "esnaf"}'::jsonb,
  NOW(),
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  role = 'courier',
  status = 'approved',
  business_name = 'tesy',
  owner_name = 'abc',
  metadata = '{"courier_type": "esnaf"}'::jsonb;

-- 4. Kontrol et:
SELECT 
  id,
  email,
  role,
  status,
  business_name,
  metadata->>'courier_type' as courier_type
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- ============================================
-- SONUÇ:
-- courier2@test.com (Şifre: önceden ayarlanmış)
-- courier1@test.com (Şifre: önceden ayarlanmış)
-- test@restorant.com (Şifre: önceden ayarlanmış)
-- 
-- Hepsi 'esnaf' tipinde kurye!
-- ============================================
