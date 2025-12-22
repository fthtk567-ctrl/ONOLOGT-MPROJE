-- ======================================================================
-- YEMEK APP ENTEGRASYON - SUPABASE SQL
-- ======================================================================
-- Tarih: 17 Kasım 2025
-- Amaç: Yemek App platformu entegrasyonu için gerekli database değişiklikleri
-- ======================================================================

-- ============================================
-- 1. DELIVERY_REQUESTS TABLOSUNA YENİ SÜTUNLAR
-- ============================================

-- Sütunları ekle
ALTER TABLE delivery_requests 
  ADD COLUMN IF NOT EXISTS external_order_id VARCHAR(100),
  ADD COLUMN IF NOT EXISTS source VARCHAR(50) DEFAULT 'manual';

-- Index'ler ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_external_order_id 
  ON delivery_requests(external_order_id);

CREATE INDEX IF NOT EXISTS idx_source 
  ON delivery_requests(source);

CREATE INDEX IF NOT EXISTS idx_source_status 
  ON delivery_requests(source, status);

-- Dökümantasyon
COMMENT ON COLUMN delivery_requests.external_order_id IS 
  'Dış platform sipariş numarası (örn: YO-4521, TR-1234)';

COMMENT ON COLUMN delivery_requests.source IS 
  'Sipariş kaynağı: manual, yemek_app, trendyol, getir';

-- Mevcut kayıtlar için varsayılan değer
UPDATE delivery_requests 
SET source = 'manual' 
WHERE source IS NULL;

COMMIT;

-- Doğrulama
SELECT 
  column_name, 
  data_type, 
  column_default, 
  is_nullable
FROM information_schema.columns
WHERE table_name = 'delivery_requests' 
  AND column_name IN ('external_order_id', 'source');

-- ============================================
-- 2. WEBHOOK TRİGGER FONKSIYONU
-- ============================================

-- Webhook gönderen fonksiyon
CREATE OR REPLACE FUNCTION notify_external_platform_on_status_change()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  payload JSONB;
  http_response RECORD;
  courier_info RECORD;
BEGIN
  -- Sadece harici platformlardan gelen siparişler için çalış
  IF NEW.source IS NOT NULL AND NEW.source != 'manual' THEN
    
    -- Platform'a göre webhook URL'i belirle
    CASE NEW.source
      WHEN 'yemek_app' THEN
        -- ⚠️ Gerçek URL Yemek App ekibi tarafından verilecek
        webhook_url := 'https://YEMEK_APP_PROJECT.supabase.co/functions/v1/onlog-status-update';
      
      WHEN 'trendyol' THEN
        webhook_url := 'https://api.trendyol.com/webhook/delivery-status';
      
      WHEN 'getir' THEN
        webhook_url := 'https://api.getir.com/webhook/delivery-status';
      
      ELSE
        webhook_url := NULL;
    END CASE;
    
    -- Webhook URL geçerliyse gönder
    IF webhook_url IS NOT NULL THEN
      
      -- Kurye bilgilerini al
      IF NEW.courier_id IS NOT NULL THEN
        SELECT owner_name, phone INTO courier_info
        FROM users 
        WHERE id = NEW.courier_id;
      END IF;
      
      -- Payload oluştur
      payload := jsonb_build_object(
        'delivery_id', NEW.id,
        'external_order_id', NEW.external_order_id,
        'status', NEW.status,
        'courier_id', NEW.courier_id,
        'courier_name', courier_info.owner_name,
        'courier_phone', courier_info.phone,
        'updated_at', NEW.updated_at,
        'source', NEW.source
      );
      
      -- HTTP POST gönder (Supabase HTTP extension kullanılmalı)
      -- Not: net.http_post için pg_net extension aktif olmalı
      BEGIN
        SELECT * INTO http_response FROM net.http_post(
          url := webhook_url,
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'X-Onlog-Source', 'onlog_webhook',
            'X-Onlog-Event', 'delivery_status_changed'
          ),
          body := payload::text
        );
        
        RAISE NOTICE 'Webhook sent to % for delivery %: HTTP %', 
          NEW.source, NEW.id, http_response.status;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Webhook failed for %: %', NEW.source, SQLERRM;
      END;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eski trigger varsa sil
DROP TRIGGER IF EXISTS trigger_notify_external_platform ON delivery_requests;

-- Yeni trigger oluştur
CREATE TRIGGER trigger_notify_external_platform
  AFTER UPDATE ON delivery_requests
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION notify_external_platform_on_status_change();

COMMIT;

-- Doğrulama
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'trigger_notify_external_platform';

-- ============================================
-- 3. TEST VERİSİ (OPSİYONEL)
-- ============================================

-- Test için örnek delivery request (gerçek merchant_id ile değiştir)
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
  'MERCHANT_ID_BURAYA_YAZ',
  2,
  350.00,
  70.00,
  63.00,
  'pending',
  '{"latitude": 41.0082, "longitude": 28.9784, "address": "Test Restoran"}',
  'Test sipariş - Yemek App entegrasyonu',
  'YO-TEST-001',
  'yemek_app'
);
*/

-- ============================================
-- 4. TEMIZLEME (GEREKİRSE)
-- ============================================

-- Test kaydını silmek için:
-- DELETE FROM delivery_requests WHERE external_order_id = 'YO-TEST-001';

-- Trigger'ı kaldırmak için:
-- DROP TRIGGER IF EXISTS trigger_notify_external_platform ON delivery_requests;
-- DROP FUNCTION IF EXISTS notify_external_platform_on_status_change();

-- Sütunları kaldırmak için (DİKKAT: Veri kaybı olur!):
-- ALTER TABLE delivery_requests DROP COLUMN IF EXISTS external_order_id;
-- ALTER TABLE delivery_requests DROP COLUMN IF EXISTS source;

-- ======================================================================
-- NOTLAR
-- ======================================================================
-- 1. Webhook URL'i güncellemek için fonksiyonu tekrar CREATE OR REPLACE yapın
-- 2. pg_net extension aktif değilse: CREATE EXTENSION IF NOT EXISTS pg_net;
-- 3. Supabase Dashboard → Database → Extensions → pg_net → Enable
-- ======================================================================
