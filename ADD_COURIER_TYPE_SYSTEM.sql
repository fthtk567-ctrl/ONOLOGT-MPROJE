-- Kurye tiplerini ayırt etmek için sistem

-- 1. users tablosuna courier_type kolonu ekle
ALTER TABLE users
ADD COLUMN IF NOT EXISTS courier_type TEXT CHECK (courier_type IN ('freelance', 'employee', 'merchant_own'));

-- 2. Varsayılan olarak freelance yap (esnaf kurye - kazanç alır)
UPDATE users 
SET courier_type = 'freelance' 
WHERE role = 'courier' AND courier_type IS NULL;

-- 3. Kontrol et - hangi kuryeler var?
SELECT 
  id,
  email,
  name,
  role,
  courier_type,
  created_at
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- 4. Kurye tipi açıklaması:
-- 'freelance'      → Esnaf kurye (teslimat ücreti alır, kazanç görür)
-- 'employee'       → SGK'lı ONLOG kuryesi (sadece maaş/prim, kazanç görMEZ)
-- 'merchant_own'   → Satıcının kendi kuryesi (kazanç görMEZ)

-- İNDEX ekle
CREATE INDEX IF NOT EXISTS idx_users_courier_type ON users(courier_type);
