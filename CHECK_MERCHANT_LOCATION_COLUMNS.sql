-- ═══════════════════════════════════════════════════
-- MERCHANT KONUM KOLONLARINI KONTROL ET
-- ═══════════════════════════════════════════════════

-- 1️⃣ Users tablosundaki konum kolonları
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
AND column_name LIKE '%location%' OR column_name LIKE '%address%'
ORDER BY column_name;

-- 2️⃣ Bir merchant kaydını incele (tam kolon isimleri için)
SELECT 
  id,
  full_name,
  business_name,
  role,
  -- Konum kolonları (hangisi varsa)
  current_location,
  business_location,
  business_address,
  address
FROM users
WHERE role = 'merchant'
LIMIT 1;

-- 3️⃣ call_courier_screen.dart'ta hangi konum kullanılıyor?
-- merchantLocation prop'u nereden geliyor?
