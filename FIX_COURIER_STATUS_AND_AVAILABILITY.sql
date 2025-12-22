-- KURYE DURUM VE UYGUNLUK DÜZELTMESİ
-- Sorun: Fatih Teke offline olmalı ama available=true, yeni SGK kurye pending durumda

-- 1. Önce mevcut durumu kontrol et
SELECT 
  id,
  full_name,
  email,
  role,
  status,
  is_available,
  is_active,
  metadata->>'courier_type' as courier_type
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- 2. Fatih Teke'yi offline yap (is_available = false)
UPDATE users
SET 
  is_available = false,  -- ❌ Offline yap
  updated_at = NOW()
WHERE email = 'fatihteke@gmail.com' -- veya 'kurye@onlog.com' 
  AND role = 'courier';

-- 3. Yeni kayıt olan SGK kuryeyi onayla ve aktif yap
-- (Email'i değiştir - son kayıt olduğun email)
UPDATE users
SET 
  status = 'approved',      -- ✅ Onaylı
  is_active = true,         -- ✅ Aktif
  is_available = true,      -- ✅ Online
  updated_at = NOW()
WHERE role = 'courier'
  AND metadata->>'courier_type' = 'sgk'  -- SGK kurye
  AND status = 'pending'                  -- Bekleyen
ORDER BY created_at DESC
LIMIT 1;

-- 4. Kontrol: Sonucu göster
SELECT 
  id,
  full_name,
  email,
  status,
  is_available AS online,
  is_active AS active,
  metadata->>'courier_type' as type,
  created_at
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- ✅ Şimdi teslimat istekleri yeni SGK kuryeye gidecek!
