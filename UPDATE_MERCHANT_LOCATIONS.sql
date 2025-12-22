-- ===================================================================
-- MERCHANT KONUMLARINI DÜZELT
-- ===================================================================
-- Her merchant kendi business konumunu görmeli!
-- ===================================================================

-- secmarket@test.com için konum güncelle
-- (Bu adresi Google Maps'ten al ve koordinatları buraya yaz)

-- Örnek: Seç Market'in gerçek adresi için:
UPDATE users
SET current_location = jsonb_build_object(
  'latitude', 41.0082,   -- ← SEÇ MARKET'İN GERÇEK LATİTUDE
  'longitude', 28.9784,  -- ← SEÇ MARKET'İN GERÇEK LONGITUDE
  'updated_at', NOW()
)
WHERE email = 'secmarket@test.com';

-- ✅ Test et:
SELECT 
  email,
  business_name,
  business_address,
  current_location
FROM users
WHERE role = 'merchant';

-- 📝 NOT: Her merchant için Google Maps'ten koordinat alıp güncelle!
-- Veya business_address'ten otomatik geocoding yap (ileride)
