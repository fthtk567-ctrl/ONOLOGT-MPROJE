-- ======================================================================
-- KURYE RED SİSTEMİ İÇİN WEBHOOK KONTROLÜ
-- ======================================================================
-- SORUN: Kurye reddedince otomatik yeni kurye atanıyor ama webhook gitmiyor
-- ÇÖZÜM: rejection_count kontrolü ekle, 3 red sonrası Yemek App'a cancelled webhook git
-- ======================================================================
-- Tarih: 27 Kasım 2025
-- ======================================================================

-- 1. delivery_requests tablosuna rejection_count kolonu var mı kontrol et
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
  AND column_name IN ('rejection_count', 'max_rejection_attempts');

-- 2. Yoksa ekle
ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS rejection_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS max_rejection_attempts INT DEFAULT 3;

-- 3. Kurye red fonksiyonunu güncelle - rejection_count artır
CREATE OR REPLACE FUNCTION handle_courier_rejection()
RETURNS TRIGGER AS $$
BEGIN
  -- Kurye red ederse (status: assigned → pending, rejected_by set)
  IF NEW.status = 'pending' 
     AND OLD.status = 'assigned' 
     AND NEW.rejected_by IS NOT NULL THEN
    
    -- Rejection count'u artır
    NEW.rejection_count := COALESCE(OLD.rejection_count, 0) + 1;
    
    RAISE NOTICE '[Rejection] Delivery % rejected by courier % (count: %)', 
      NEW.id, NEW.rejected_by, NEW.rejection_count;
    
    -- 3 red sonrası iptal et
    IF NEW.rejection_count >= NEW.max_rejection_attempts THEN
      NEW.status := 'cancelled';
      NEW.cancellation_reason := 'Kurye bulunamadı - ' || NEW.rejection_count || ' red';
      
      RAISE NOTICE '[Rejection] Delivery % CANCELLED after % rejections', 
        NEW.id, NEW.rejection_count;
      
      -- ⭐ Bu durumda webhook gidecek çünkü status='cancelled' oldu
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger'ı oluştur
DROP TRIGGER IF EXISTS trigger_handle_courier_rejection ON delivery_requests;

CREATE TRIGGER trigger_handle_courier_rejection
  BEFORE UPDATE OF status, rejected_by ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION handle_courier_rejection();

-- 5. Doğrulama
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_handle_courier_rejection';

COMMIT;

-- ======================================================================
-- AÇIKLAMA
-- ======================================================================
/*
NASIL ÇALIŞIR:

1. Kurye 1 reddeder → status: 'assigned' → 'pending'
   └─ rejection_count: 0 → 1
   └─ ❌ Webhook GİTMEZ (status 'pending')
   └─ Otomatik yeni kurye ataması başlar

2. Kurye 2 reddeder → status: 'assigned' → 'pending'
   └─ rejection_count: 1 → 2
   └─ ❌ Webhook GİTMEZ (status 'pending')
   └─ Otomatik yeni kurye ataması başlar

3. Kurye 3 reddeder → status: 'assigned' → 'cancelled'
   └─ rejection_count: 2 → 3 (MAX!)
   └─ status: 'cancelled'
   └─ ✅ WEBHOOK GİDER (Yemek App'a: "Kurye bulunamadı")
   └─ cancellation_reason: "Kurye bulunamadı - 3 red"

YEMEK APP'A GİDECEK MESAJ:
{
  "status": "cancelled",
  "status_message": "Sipariş iptal edildi",
  "cancellation_reason": "Kurye bulunamadı - 3 red"
}
*/

-- ======================================================================
-- TEST SENARYOSU
-- ======================================================================

-- Test 1: Yeni sipariş oluştur
/*
INSERT INTO delivery_requests (
  merchant_id,
  source,
  external_order_id,
  status,
  package_count,
  declared_amount,
  pickup_location,
  delivery_location,
  rejection_count,
  max_rejection_attempts
) VALUES (
  'MERCHANT_UUID',
  'yemek_app',
  'YO-TEST-REJECTION',
  'pending',
  1,
  100.00,
  '{"latitude": 41.0, "longitude": 29.0, "address": "Restoran"}',
  '{"latitude": 41.1, "longitude": 29.1, "address": "Müşteri"}',
  0,
  3
);
*/

-- Test 2: Kurye 1 ataması (otomatik)
-- Status: pending → assigned

-- Test 3: Kurye 1 red (manuel)
/*
UPDATE delivery_requests
SET 
  status = 'pending',
  courier_id = NULL,
  rejected_by = 'COURIER_1_UUID'
WHERE external_order_id = 'YO-TEST-REJECTION';
-- rejection_count: 0 → 1, status: 'pending', webhook GİTMEZ ❌
*/

-- Test 4: Kurye 2 ataması (otomatik)
-- Status: pending → assigned

-- Test 5: Kurye 2 red (manuel)
/*
UPDATE delivery_requests
SET 
  status = 'pending',
  courier_id = NULL,
  rejected_by = 'COURIER_2_UUID'
WHERE external_order_id = 'YO-TEST-REJECTION';
-- rejection_count: 1 → 2, status: 'pending', webhook GİTMEZ ❌
*/

-- Test 6: Kurye 3 ataması (otomatik)
-- Status: pending → assigned

-- Test 7: Kurye 3 red (manuel) - SON RED!
/*
UPDATE delivery_requests
SET 
  status = 'pending',
  courier_id = NULL,
  rejected_by = 'COURIER_3_UUID'
WHERE external_order_id = 'YO-TEST-REJECTION';
-- rejection_count: 2 → 3 (MAX!)
-- status: 'cancelled' (Trigger otomatik değiştirir)
-- webhook GİDER Yemek App'a! ✅
*/

-- Test 8: Kontrolü
/*
SELECT 
  id,
  external_order_id,
  status,
  rejection_count,
  cancellation_reason
FROM delivery_requests
WHERE external_order_id = 'YO-TEST-REJECTION';

-- Beklenen:
-- status: 'cancelled'
-- rejection_count: 3
-- cancellation_reason: 'Kurye bulunamadı - 3 red'
*/
