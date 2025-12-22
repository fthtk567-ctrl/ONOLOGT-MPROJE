-- ============================================
-- KOLAY YOL: EKSİK KULLANICILARI EKLE
-- (UUID muhabeti yok!)
-- ============================================

-- ============================================
-- 1️⃣ ÖNCE SUPABASE AUTHENTICATION'DA OLUŞTUR
-- ============================================
-- https://supabase.com/dashboard/project/oilldfyywtzybrmpyixx/auth/users
-- "Add User" butonuna tıkla, şu 2 kullanıcıyı oluştur:
--
-- 1. Email: admin@onlog.com, Password: 123456
-- 2. Email: courier@onlog.com, Password: 123456
--
-- ⚠️ "Auto Confirm User?" kutusunu İŞARETLE! (✓)
-- ============================================


-- ============================================
-- 2️⃣ BU SQL'İ ÇALIŞTIR (Otomatik UUID bulacak!)
-- ============================================

-- ADMIN KULLANICISI (Authentication'daki UUID'yi otomatik bulur)
INSERT INTO public.users (
  id,
  email,
  phone,
  role,
  status,
  is_active,
  created_at,
  updated_at
)
SELECT 
  id,
  'admin@onlog.com',
  '+905551234567',
  'superAdmin',
  'approved',
  true,
  NOW(),
  NOW()
FROM auth.users
WHERE email = 'admin@onlog.com'
ON CONFLICT (id) DO UPDATE SET
  role = 'superAdmin',
  status = 'approved',
  is_active = true;


-- COURIER KULLANICISI
INSERT INTO public.users (
  id,
  email,
  phone,
  role,
  status,
  is_active,
  business_name,
  metadata,
  created_at,
  updated_at
)
SELECT 
  id,
  'courier@onlog.com',
  '+905552223344',
  'courier',
  'approved',
  true,
  'Test Kurye',
  jsonb_build_object(
    'courier_type', 'esnaf',
    'vehicle_type', 'motor',
    'license_plate', '34ABC123'
  ),
  NOW(),
  NOW()
FROM auth.users
WHERE email = 'courier@onlog.com'
ON CONFLICT (id) DO UPDATE SET
  role = 'courier',
  status = 'approved',
  is_active = true;


-- ============================================
-- 3️⃣ KONTROL ET
-- ============================================

SELECT 
  email,
SELECT 
  email,
  business_name,
  role,
  status,
  is_active
FROM public.users
ORDER BY role, email;
-- ============================================
-- 4️⃣ WALLET'LARI OLUŞTUR
-- ============================================

-- Merchant Wallet (merchantt@test.com için)
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
--   Password: 123456
--
-- MERCHANT PANEL (localhost:3001):
--   Email: merchantt@test.com
--   Password: 123456
--
-- COURIER APP (localhost:5000):
--   Email: courier@onlog.com
--   Password: 123456
-- ============================================
-- COURIER APP (localhost:5000):
--   Email: courier@onlog.com
--   Password: courier123