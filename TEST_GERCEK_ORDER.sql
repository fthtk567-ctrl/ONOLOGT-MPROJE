-- ============================================
-- GERÇEK ORDER İLE QR + GPS TEST
-- ============================================
-- Senin gerçek sipariş ID'n: 72ffaa29-aa7a-42f7-9d6a-debe86238079
-- ============================================

-- 1. Sipariş detaylarını kontrol et
SELECT 
  id,
  merchant_name,
  declared_amount,
  merchant_location,
  courier_id,
  status
FROM delivery_requests
WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079';

-- 2. QR Hash oluştur (1500 TL için)
SELECT generate_qr_hash(
  '72ffaa29-aa7a-42f7-9d6a-debe86238079'::UUID, 
  1500.00
) as qr_hash_for_order;

-- 3. GPS testi (Konya koordinatları - Cumra örnek)
SELECT * FROM verify_gps_location(
  '72ffaa29-aa7a-42f7-9d6a-debe86238079'::UUID,
  37.5671, -- Teslimat yapılan yer latitude
  32.7883  -- Teslimat yapılan yer longitude
);

-- ============================================
-- ⚠️ SORUN: merchant_location = NULL!
-- ============================================
-- GPS testi çalışmaz çünkü merchant lokasyonu yok!
-- 
-- ÇÖZÜM: Merchant lokasyonu ekle:

UPDATE delivery_requests
SET merchant_location = jsonb_build_object(
  'latitude', 37.5671,
  'longitude', 32.7883,
  'address', 'Konya Çumra Test Merchant'
)
WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079';

-- Şimdi tekrar GPS testi yap:
SELECT * FROM verify_gps_location(
  '72ffaa29-aa7a-42f7-9d6a-debe86238079'::UUID,
  37.5680, -- 100m yakın bir nokta
  32.7890
);

-- ============================================
-- QR HASH'İ SİPARİŞE KAYDET
-- ============================================
-- Merchant QR kod oluştururken bu hash'i kaydeder:

UPDATE delivery_requests
SET qr_code_hash = (
  SELECT generate_qr_hash(
    '72ffaa29-aa7a-42f7-9d6a-debe86238079'::UUID, 
    1500.00
  )
)
WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079';

-- ============================================
-- QR KOD DOĞRULAMA TESTİ
-- ============================================
-- Kurye QR taratınca bu çalışır:

SELECT * FROM verify_qr_code(
  '72ffaa29-aa7a-42f7-9d6a-debe86238079'::UUID,
  (SELECT qr_code_hash FROM delivery_requests WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079')
);

-- YANLIŞ HASH İLE TEST (dolandırıcılık simülasyonu):
SELECT * FROM verify_qr_code(
  '72ffaa29-aa7a-42f7-9d6a-debe86238079'::UUID,
  'fake_hash_1234567890abcdef' -- Yanlış hash
);

-- ============================================
-- TAM TESLİMAT AKIŞI
-- ============================================

-- 1. Merchant lokasyonu + QR hash ekle
UPDATE delivery_requests
SET 
  merchant_location = jsonb_build_object(
    'latitude', 37.5671,
    'longitude', 32.7883,
    'address', 'Konya Çumra Test Merchant'
  ),
  qr_code_hash = (SELECT generate_qr_hash(id::UUID, declared_amount) FROM delivery_requests WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079')
WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079';

-- 2. QR doğrula (kurye taratınca)
SELECT * FROM verify_qr_code(
  '72ffaa29-aa7a-42f7-9d6a-debe86238079'::UUID,
  (SELECT qr_code_hash FROM delivery_requests WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079')
);

-- 3. GPS doğrula (teslimat anında)
SELECT * FROM verify_gps_location(
  '72ffaa29-aa7a-42f7-9d6a-debe86238079'::UUID,
  37.5675, -- Merchant'dan 50m uzak
  32.7885
);

-- 4. Teslim et (QR+GPS+Fotoğraf)
SELECT * FROM complete_delivery_with_verification(
  '72ffaa29-aa7a-42f7-9d6a-debe86238079'::UUID,
  '250f4abe-858a-457b-b972-9a76340b07c2'::UUID, -- Senin courier_id
  37.5675, -- Teslimat GPS
  32.7885,
  'https://storage.supabase.co/delivery_photos/test_photo.jpg', -- Fotoğraf URL
  NULL -- İmza (opsiyonel)
);

-- Final kontrol
SELECT 
  id,
  declared_amount,
  qr_verified,
  gps_verified,
  gps_distance_meters,
  verification_status,
  delivery_photo_url,
  status
FROM delivery_requests
WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079';
