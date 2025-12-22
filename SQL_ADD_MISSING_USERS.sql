-- ============================================
-- EKSİK KULLANICILARI EKLE (merchantt@test.com KALSIN)
-- ============================================

-- ============================================
-- 1️⃣ ÖNCE AUTHENTICATION'DA OLUŞTUR (Manuel)
-- ============================================
-- https://supabase.com/dashboard/project/oilldfyywtzybrmpyixx/auth/users
-- "Add User" butonuna tıkla

/*
OLUŞTURULACAK KULLANICILAR:

1. ADMIN:
   Email: admin@onlog.com
   Password: admin123
   ⚠️ "Confirm email" kutusunu KALDIRMA!

2. COURIER 1:
   Email: courier1@onlog.com
   Password: courier123
   ⚠️ "Confirm email" kutusunu KALDIRMA!

3. COURIER 2:
   Email: courier2@onlog.com
   Password: courier123
   ⚠️ "Confirm email" kutusunu KALDIRMA!
*/


-- ============================================
-- 2️⃣ UUID'LERİ KOPYALA VE ASAĞIYA YAPISTIR
-- ============================================
-- Authentication'da her kullanıcının UID'sini kopyala!

-- ADMIN KULLANICISI
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
  'ADMIN-UUID-BURAYA',  -- ← Authentication'dan admin@onlog.com UUID'sini kopyala
  'admin@onlog.com',
  'System Admin',
  '+905551234567',
  'superAdmin',
  'approved',
  true,
  NOW(),
  NOW()
);

-- COURIER 1 KULLANICISI
INSERT INTO public.users (
  id,
  email,
  full_name,
  phone,
  role,
  status,
  is_active,
  business_name,
  metadata,
  created_at,
  updated_at
) VALUES (
  'COURIER1-UUID-BURAYA',  -- ← Authentication'dan courier1@onlog.com UUID'sini kopyala
  'courier1@onlog.com',
  'Ahmet Kurye',
  '+905552223344',
  'courier',
  'approved',
  true,
  'Ahmet Kurye',
  jsonb_build_object(
    'courier_type', 'esnaf',
    'vehicle_type', 'motor',
    'license_plate', '34ABC123'
  ),
  NOW(),
  NOW()
);

-- COURIER 2 KULLANICISI
INSERT INTO public.users (
  id,
  email,
  full_name,
  phone,
  role,
  status,
  is_active,
  business_name,
  metadata,
  created_at,
  updated_at
) VALUES (
  'COURIER2-UUID-BURAYA',  -- ← Authentication'dan courier2@onlog.com UUID'sini kopyala
  'courier2@onlog.com',
  'Mehmet Kurye',
  '+905553334455',
  'courier',
  'approved',
  true,
  'Mehmet Kurye',
  jsonb_build_object(
    'courier_type', 'esnaf',
    'vehicle_type', 'bisiklet',
    'license_plate', NULL
  ),
  NOW(),
  NOW()
);


-- ============================================
-- 3️⃣ KONTROL ET
-- ============================================

SELECT 
  id,
  email,
  full_name,
  role,
  status,
  is_active,
  business_name
FROM public.users
ORDER BY role, email;


-- ============================================
-- 4️⃣ WALLET'LARI OLUŞTUR
-- ============================================

-- Merchant Wallet (merchantt@test.com için)
INSERT INTO merchant_wallets (merchant_id, balance, currency)
SELECT id, 0.0, 'TRY'
FROM users
WHERE role = 'merchant' AND email = 'merchantt@test.com'
ON CONFLICT (merchant_id) DO NOTHING;

-- Courier Wallets
INSERT INTO courier_wallets (courier_id, balance, currency)
SELECT id, 0.0, 'TRY'
FROM users
WHERE role = 'courier'
ON CONFLICT (courier_id) DO NOTHING;

-- Wallet kontrolü
SELECT 
  u.email,
  u.role,
  COALESCE(mw.balance, cw.balance, 0) as wallet_balance
FROM users u
LEFT JOIN merchant_wallets mw ON u.id = mw.merchant_id
LEFT JOIN courier_wallets cw ON u.id = cw.courier_id
ORDER BY u.role, u.email;


-- ============================================
-- ✅ TAMAMLANDI!
-- ============================================
-- GİRİŞ BİLGİLERİ:
-- 
-- ADMIN PANEL (localhost:4000):
--   Email: admin@onlog.com
--   Password: admin123
--
-- MERCHANT PANEL (localhost:3001):
--   Email: merchantt@test.com
--   Password: merchant123
--
-- COURIER APP (localhost:5000):
--   Email: courier1@onlog.com veya courier2@onlog.com
--   Password: courier123
-- ============================================
