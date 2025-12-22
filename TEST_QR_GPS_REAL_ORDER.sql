-- ============================================
-- GERÇEK SİPARİŞ İLE QR + GPS TEST
-- ============================================

-- 1. Önce bir gerçek sipariş ID'si al
SELECT 
  id,
  merchant_id,
  merchant_name,
  declared_amount,
  courier_id,
  status,
  merchant_location
FROM delivery_requests
WHERE courier_id = '250f4abe-858a-457b-b972-9a76340b07c2' -- Test kurye
ORDER BY created_at DESC
LIMIT 1;

-- 2. Bu sipariş için QR hash oluştur
-- (Yukarıdaki sonuçtan ID ve declared_amount al)
-- Örnek: 
-- SELECT generate_qr_hash(
--   'GERÇEK_ORDER_ID'::UUID,
--   GERÇEK_TUTAR
-- );

-- 3. GPS konumunu test et (Konya Çumra koordinatları)
-- SELECT * FROM verify_gps_location(
--   'GERÇEK_ORDER_ID'::UUID,
--   37.5671, -- Kurye konumu (Konya Çumra)
--   32.7883
-- );

-- 4. QR hash'i siparişe kaydet (normalde merchant yapar)
-- UPDATE delivery_requests
-- SET qr_code_hash = 'HASH_BURAYA'
-- WHERE id = 'GERÇEK_ORDER_ID'::UUID;

-- ✅ ADIMLAR:
-- 1. Yukarıdaki SELECT'i çalıştır
-- 2. Dönen order_id ve declared_amount'u not et
-- 3. generate_qr_hash fonksiyonunu bu değerlerle çalıştır
-- 4. GPS testini yap
