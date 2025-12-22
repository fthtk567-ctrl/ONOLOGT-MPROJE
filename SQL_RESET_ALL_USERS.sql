-- ============================================
-- TÜM KULLANICILARI SİL VE YENİDEN OLUŞTUR
-- ============================================
-- NOT: Bu script'i Supabase SQL Editor'de çalıştırın
-- ============================================

-- 1️⃣ ÖNCE PUBLIC.USERS TABLOSUNU TEMİZLE
-- ============================================
DELETE FROM public.users;

-- Confirm
SELECT COUNT(*) as "Kalan Kullanıcı Sayısı" FROM public.users;


-- 2️⃣ YENİ KULLANICILAR OLUŞTUR
-- ============================================
-- NOT: Authentication'daki kullanıcıları da manuel silmek gerekebilir!
-- https://supabase.com/dashboard/project/oilldfyywtzybrmpyixx/auth/users
-- "Delete" butonuyla tüm kullanıcıları sil

-- ============================================
-- 3️⃣ AUTHENTICATION'DA YENİ KULLANICILAR OLUŞTUR
-- ============================================
-- Manuel olarak şu kullanıcıları oluştur:
-- https://supabase.com/dashboard/project/oilldfyywtzybrmpyixx/auth/users
-- "Add User" > "Create new user"

/*
1. SUPER ADMIN:
   Email: admin@onlog.com
   Password: admin123
   Email Confirm: YES (Confirm email kutusunu KALDIRMA)

2. MERCHANT (İşletme):
   Email: merchant@onlog.com
   Password: merchant123
   Email Confirm: YES

3. COURIER 1 (Kurye):
   Email: courier1@onlog.com
   Password: courier123
   Email Confirm: YES

4. COURIER 2 (Kurye):
   Email: courier2@onlog.com
   Password: courier123
   Email Confirm: YES
*/


-- ============================================
-- 4️⃣ PUBLIC.USERS TABLOSUNA EKLE
-- ============================================
-- Önce Authentication'daki UUID'leri kopyala!

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
  'BURAYA-ADMIN-UUID-YAPISTIR',  -- ← Authentication'dan admin@onlog.com UUID'sini kopyala
  'admin@onlog.com',
  'System Admin',
  '+905551234567',
  'superAdmin',
  'approved',
  true,
  NOW(),
  NOW()
);

-- MERCHANT KULLANICISI
INSERT INTO public.users (
  id,
  email,
  full_name,
  phone,
  role,
  status,
  is_active,
  business_name,
  address,
  latitude,
  longitude,
  created_at,
  updated_at
) VALUES (
  'BURAYA-MERCHANT-UUID-YAPISTIR',  -- ← Authentication'dan merchant@onlog.com UUID'sini kopyala
  'merchant@onlog.com',
  'Test Restaurant',
  '+905551112233',
  'merchant',
  'approved',
  true,
  'Test Restaurant',
  'Kadıköy, İstanbul',
  40.9887,
  29.0262,
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
  'BURAYA-COURIER1-UUID-YAPISTIR',  -- ← Authentication'dan courier1@onlog.com UUID'sini kopyala
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
  'BURAYA-COURIER2-UUID-YAPISTIR',  -- ← Authentication'dan courier2@onlog.com UUID'sini kopyala
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
-- 5️⃣ KONTROL ET
-- ============================================

-- Tüm kullanıcıları listele
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

-- Rollere göre sayıları kontrol et
SELECT 
  role,
  COUNT(*) as count
FROM public.users
GROUP BY role;


-- ============================================
-- 6️⃣ WALLET'LARI OLUŞTUR (Ödeme sistemi için)
-- ============================================

-- Merchant Wallet
INSERT INTO merchant_wallets (merchant_id, balance, currency)
SELECT id, 0.0, 'TRY'
FROM users
WHERE role = 'merchant'
ON CONFLICT (merchant_id) DO NOTHING;

-- Courier Wallets
INSERT INTO courier_wallets (courier_id, balance, currency)
SELECT id, 0.0, 'TRY'
FROM users
WHERE role = 'courier'
ON CONFLICT (courier_id) DO NOTHING;

-- Kontrol
SELECT 
  u.email,
  u.role,
  COALESCE(mw.balance, cw.balance, 0) as wallet_balance
FROM users u
LEFT JOIN merchant_wallets mw ON u.id = mw.merchant_id
LEFT JOIN courier_wallets cw ON u.id = cw.courier_id
WHERE u.role IN ('merchant', 'courier');


-- ============================================
-- ✅ TAMAMLANDI!
-- ============================================
-- Giriş Bilgileri:
-- 
-- ADMIN PANEL (localhost:4000):
--   Email: admin@onlog.com
--   Password: admin123
--
-- MERCHANT PANEL (localhost:3001):
--   Email: merchant@onlog.com
--   Password: merchant123
--
-- COURIER APP (localhost:5000):
--   Email: courier1@onlog.com veya courier2@onlog.com
--   Password: courier123
-- ============================================
