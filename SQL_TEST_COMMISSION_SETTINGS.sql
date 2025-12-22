-- ============================================
-- TEST: FARKLI KOMİSYON AYARLARI
-- ============================================

-- 1. Mevcut merchant'a %20 yüzde bazlı komisyon (DEFAULT)
UPDATE users
SET commission_settings = '{"type": "percentage", "rate": 20.0}'::jsonb
WHERE email = 'merchantt@test.com';

-- 2. Test için farklı merchant'lar ekle (opsiyonel)

-- Merchant 2: %30 yüzde bazlı
-- UPDATE users
-- SET commission_settings = '{"type": "percentage", "rate": 30.0}'::jsonb
-- WHERE email = 'merchant2@test.com';

-- Merchant 3: Paket başı 50 TL sabit ücret
-- UPDATE users
-- SET commission_settings = '{"type": "fixed_per_package", "fixed_amount": 50.0}'::jsonb
-- WHERE email = 'merchant3@test.com';

-- 3. Kontrol et
SELECT 
  id,
  email,
  business_name,
  commission_settings,
  commission_settings->>'type' as commission_type,
  commission_settings->>'rate' as percentage_rate,
  commission_settings->>'fixed_amount' as fixed_per_package
FROM users
WHERE role = 'merchant';

-- ============================================
-- SONUÇ:
-- merchantt@test.com → {"type": "percentage", "rate": 20.0}
-- Kurye çağırdığında: 100 TL paket → %20 = 20 TL komisyon
-- ============================================
