-- MESAİ SİSTEMİ TEST - TELEFONSUZ
-- Kurye mesaiye başladığını simüle edelim

-- 1. Mevcut durumu kontrol et
SELECT 
  id,
  full_name,
  email,
  role,
  status,
  is_available AS mesaide_mi,
  is_active,
  metadata->>'courier_type' as kurye_tipi
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- 2. Yeni SGK kuryeyi mesaiye başlat (simüle et)
UPDATE users
SET 
  status = 'approved',           -- ✅ Onaylı
  is_active = true,              -- ✅ Aktif
  is_available = true,           -- 🟢 MESAİYE BAŞLADI!
  updated_at = NOW()
WHERE role = 'courier'
  AND metadata->>'courier_type' = 'sgk'  -- Son kayıt olan SGK kurye
  AND status = 'pending'
ORDER BY created_at DESC
LIMIT 1;

-- 3. Fatih Teke'yi mesai dışı yap
UPDATE users
SET 
  is_available = false,          -- 🔴 MESAİ DIŞ
  updated_at = NOW()
WHERE email = 'fatihteke@gmail.com' 
  AND role = 'courier';

-- 4. Kontrol: Mesaide olan kuryeleri göster
SELECT 
  id,
  full_name,
  email,
  is_available AS '🟢 Mesaide',
  status AS durum,
  metadata->>'courier_type' as tip,
  created_at
FROM users
WHERE role = 'courier'
ORDER BY is_available DESC, created_at DESC;

-- ✅ Şimdi Merchant Panel'den "Kurye Çağır" yapabilirsin!
-- Sipariş SGK kuryeye gidecek (is_available=true olan tek kurye o)
