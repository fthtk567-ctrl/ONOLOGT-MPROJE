-- ============================================
-- SON OLUŞTURULAN DELIVERY REQUEST KONTROL
-- ============================================

-- EN SON oluşturulan delivery request'i göster (son 1 saat)
SELECT 
  id,
  merchant_id,
  courier_id,  -- ❓ Bu dolu mu yoksa NULL mı?
  status,
  declared_amount,
  courier_payment_due,
  pickup_location,
  delivery_location,
  created_at,
  updated_at
FROM delivery_requests
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 5;

-- Bu sorgu son 5 delivery request'i gösterecek
-- ✅ courier_id DOLU ise → Trigger tetiklenmeliydi
-- ❌ courier_id NULL ise → Sorun burada! Kurye atanmamış!
