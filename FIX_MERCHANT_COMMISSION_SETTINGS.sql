-- TEST SANAYI TOPTAN merchant'ın commission_settings'ini düzelt
-- Paket başı 50₺ olarak ayarla

UPDATE users
SET 
  commission_settings = jsonb_build_object(
    'type', 'perOrder',
    'business_type', 'industrial',
    'per_order_fee', 50.0,
    'commission_rate', null,
    'minimum_order', 0
  ),
  updated_at = NOW()
WHERE email = 'onlogprojects@gmail.com'
  AND role = 'merchant';

-- Kontrol et
SELECT 
  email,
  business_name,
  commission_settings
FROM users
WHERE email = 'onlogprojects@gmail.com';
