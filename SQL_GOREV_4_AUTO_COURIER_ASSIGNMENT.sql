-- ======================================================================
-- GÖREV 4: OTOMATİK KURYE ATAMA TRİGGER'I
-- Yeni delivery_request oluşunca en uygun kuryeyi otomatik atar
-- ======================================================================
-- Tarih: 17 Kasım 2025
-- Kullanım: Supabase Dashboard → SQL Editor → Yeni sorgu → Bu kodu yapıştır → Run
-- ======================================================================

-- 1. Kurye atama fonksiyonu
CREATE OR REPLACE FUNCTION auto_assign_courier_to_delivery()
RETURNS TRIGGER AS $$
DECLARE
  best_courier_id UUID;
  pickup_lat DECIMAL;
  pickup_lng DECIMAL;
  courier_info RECORD;
BEGIN
  -- Sadece pending durumundaki siparişler için
  IF NEW.status = 'pending' THEN
    
    -- Pickup lokasyonunu al
    pickup_lat := (NEW.pickup_location->>'latitude')::DECIMAL;
    pickup_lng := (NEW.pickup_location->>'longitude')::DECIMAL;
    
    RAISE NOTICE '[Auto Assign] Finding courier for delivery %, pickup: %, %', 
      NEW.id, pickup_lat, pickup_lng;
    
    -- En uygun kuryeyi bul (CourierAssignmentService mantığı)
    SELECT id INTO best_courier_id
    FROM users
    WHERE role = 'courier'
      AND is_active = true
      AND is_available = true
      AND is_busy = false
      AND status = 'approved'
      -- Lokasyon kontrolü (basitleştirilmiş - gerçek sistemde ST_Distance kullan)
      AND (
        (current_location->>'latitude')::DECIMAL IS NOT NULL
        AND (current_location->>'longitude')::DECIMAL IS NOT NULL
      )
    ORDER BY 
      average_rating DESC NULLS LAST, -- Önce yüksek rating
      created_at ASC -- Sonra eski kayıtlı olanlar (adil dağılım)
    LIMIT 1;
    
    -- Kurye bulunduysa ata
    IF best_courier_id IS NOT NULL THEN
      
      -- Kurye bilgilerini al
      SELECT owner_name, phone INTO courier_info
      FROM users 
      WHERE id = best_courier_id;
      
      -- Delivery'yi güncelle
      UPDATE delivery_requests
      SET 
        courier_id = best_courier_id,
        status = 'assigned',
        updated_at = NOW()
      WHERE id = NEW.id;
      
      RAISE NOTICE '[Auto Assign] Assigned courier % (%) to delivery %', 
        courier_info.owner_name, best_courier_id, NEW.id;
      
      -- Kurye'ye FCM bildirimi gönder
      BEGIN
        PERFORM net.http_post(
          url := current_setting('app.supabase_url', true) || '/functions/v1/send-fcm-notification',
          headers := jsonb_build_object(
            'Authorization', 'Bearer ' || current_setting('app.service_role_key', true),
            'Content-Type', 'application/json'
          ),
          body := jsonb_build_object(
            'userId', best_courier_id,
            'title', CASE 
              WHEN NEW.source = 'yemek_app' THEN '🍕 Yeni Yemek App Teslimatı!'
              WHEN NEW.source = 'trendyol' THEN '🛍️ Yeni Trendyol Teslimatı!'
              WHEN NEW.source = 'getir' THEN '🚀 Yeni Getir Teslimatı!'
              ELSE '📦 Yeni Teslimat!'
            END,
            'body', NEW.package_count || ' paket - ' || NEW.declared_amount || '₺',
            'data', jsonb_build_object(
              'type', 'NEW_DELIVERY',
              'deliveryId', NEW.id,
              'source', COALESCE(NEW.source, 'manual'),
              'externalOrderId', NEW.external_order_id
            )
          )::text
        );
        
        RAISE NOTICE '[Auto Assign] FCM notification sent to courier %', best_courier_id;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[Auto Assign] FCM notification failed: %', SQLERRM;
      END;
      
    ELSE
      RAISE WARNING '[Auto Assign] No available courier found for delivery %', NEW.id;
      
      -- Merchant'a kurye bulunamadı bildirimi gönder (opsiyonel)
      BEGIN
        PERFORM net.http_post(
          url := current_setting('app.supabase_url', true) || '/functions/v1/send-fcm-notification',
          headers := jsonb_build_object(
            'Authorization', 'Bearer ' || current_setting('app.service_role_key', true),
            'Content-Type', 'application/json'
          ),
          body := jsonb_build_object(
            'userId', NEW.merchant_id,
            'title', '⚠️ Kurye Bulunamadı',
            'body', 'Teslimat için müsait kurye yok. Manuel atama yapabilirsiniz.',
            'data', jsonb_build_object(
              'type', 'NO_COURIER_AVAILABLE',
              'deliveryId', NEW.id
            )
          )::text
        );
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[Auto Assign] Merchant notification failed: %', SQLERRM;
      END;
      
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Eski trigger varsa sil
DROP TRIGGER IF EXISTS trigger_auto_assign_courier ON delivery_requests;

-- 3. Yeni trigger oluştur
CREATE TRIGGER trigger_auto_assign_courier
  AFTER INSERT ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_courier_to_delivery();

-- 4. Doğrulama
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_assign_courier';

COMMIT;

-- ======================================================================
-- TEST KOMUTLARI
-- ======================================================================

-- Test 1: Manuel delivery request oluştur (otomatik kurye ataması yapmalı)
/*
INSERT INTO delivery_requests (
  merchant_id,
  package_count,
  declared_amount,
  merchant_payment_due,
  courier_payment_due,
  status,
  pickup_location,
  notes,
  external_order_id,
  source
) VALUES (
  (SELECT id FROM users WHERE role = 'merchant' LIMIT 1), -- İlk merchant
  1,
  50.00,
  10.00,
  0,
  'pending', -- ⭐ Trigger burada tetiklenir
  jsonb_build_object(
    'latitude', 41.0082,
    'longitude', 28.9784,
    'address', 'Test Lokasyon'
  ),
  'Test sipariş - Otomatik kurye ataması',
  'TEST-AUTO-' || extract(epoch from now())::text,
  'manual'
);
*/

-- Test 2: Atanan kuryeyi kontrol et
/*
SELECT 
  id,
  external_order_id,
  status,
  courier_id,
  (SELECT owner_name FROM users WHERE id = delivery_requests.courier_id) as courier_name
FROM delivery_requests
WHERE external_order_id LIKE 'TEST-AUTO-%'
ORDER BY created_at DESC
LIMIT 1;
-- Beklenen: status = 'assigned', courier_id = (bir UUID)
*/

-- Test 3: Supabase Logs kontrolü
-- Dashboard → Logs → Database → "Auto Assign" ara
-- "[Auto Assign] Assigned courier X to delivery Y" mesajını göreceksin

-- Test 4: Test kaydını temizle
/*
DELETE FROM delivery_requests WHERE external_order_id LIKE 'TEST-AUTO-%';
*/

-- ======================================================================
-- NOTLAR
-- ======================================================================
-- 1. Bu basit bir kurye atama algoritmasıdır. Gerçek sistemde:
--    - GPS mesafe hesabı (ST_Distance ile PostGIS)
--    - Kurye yük dengeleme
--    - Platform bazlı önceliklendirme
--    - Zaman dilimi kontrolü (mesai saatleri)
--    gibi özellikler eklenebilir.
--
-- 2. current_setting() fonksiyonları için Supabase'de ayarlar gerekli:
--    ALTER DATABASE postgres SET app.supabase_url = 'https://xxx.supabase.co';
--    ALTER DATABASE postgres SET app.service_role_key = 'eyJxxx...';
--
-- 3. pg_net extension aktif olmalı: CREATE EXTENSION IF NOT EXISTS pg_net;
-- ======================================================================
