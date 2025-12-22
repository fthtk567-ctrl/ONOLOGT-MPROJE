-- ======================================================================
-- YEMEK APP WEBHOOK TRIGGER - FİNAL VERSİYON
-- ======================================================================
-- Yemek App'in verdiği bilgiler:
-- URL: https://avpbrcqbhxyctmwnxtmm.supabase.co/functions/v1/onlog-status-update
-- Secret: yemek_app_webhook_secret_2025
-- Signature: HMAC-SHA256
-- ======================================================================

-- 1. HTTP extension'ı aktif et (gerekli)
CREATE EXTENSION IF NOT EXISTS http;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Webhook function'ı oluştur
CREATE OR REPLACE FUNCTION notify_yemek_app_on_status_change()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT := 'https://avpbrcqbhxyctmwnxtmm.supabase.co/functions/v1/onlog-status-update';
  webhook_secret TEXT := 'yemek_app_webhook_secret_2025';
  yemek_app_anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2cGJyY3FiaHh5Y3Rtd254dG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0MDc5NTAsImV4cCI6MjA3ODk4Mzk1MH0.L7GP6WI5qi1QUAMJWsOx3CcplBfB8pIQQqbpODy1QOk';
  payload JSONB;
  payload_text TEXT;
  signature TEXT;
  timestamp_val BIGINT;
  http_response RECORD;
  courier_info RECORD;
  status_message TEXT;
BEGIN
  RAISE NOTICE '[Yemek App Webhook] Trigger fired - delivery_id: %, status: %', NEW.id, NEW.status;
  
  -- Sadece Yemek App siparişleri için
  IF NEW.source IS NULL OR NEW.source != 'yemek_app' THEN
    RAISE NOTICE '[Yemek App Webhook] Skipping - source is not yemek_app';
    RETURN NEW;
  END IF;
  
  -- Sadece belirli statuslarda webhook gönder
  IF NEW.status NOT IN ('accepted', 'picked_up', 'delivered', 'cancelled') THEN
    RAISE NOTICE '[Yemek App Webhook] Skipping - status % not in webhook list', NEW.status;
    RETURN NEW;
  END IF;
  
  -- Kurye bilgilerini al
  IF NEW.courier_id IS NOT NULL THEN
    SELECT owner_name, phone INTO courier_info
    FROM users 
    WHERE id = NEW.courier_id;
  END IF;
  
  -- Status mesajı belirle
  CASE NEW.status
    WHEN 'accepted' THEN
      status_message := 'Kurye siparişi kabul etti';
    WHEN 'picked_up' THEN
      status_message := 'Sipariş kurye tarafından alındı, teslimata gidiyor';
    WHEN 'delivered' THEN
      status_message := 'Sipariş başarıyla teslim edildi';
    WHEN 'cancelled' THEN
      status_message := 'Teslimat iptal edildi';
    ELSE
      status_message := 'Durum güncellendi';
  END CASE;
  
  -- Payload oluştur (Yemek App'in istediği format)
  payload := jsonb_build_object(
    'external_order_id', NEW.external_order_id,
    'delivery_id', NEW.id,
    'status', NEW.status,
    'timestamp', to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'updated_at', to_char(NEW.updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'source', 'onlog',
    'message', status_message
  );
  
  -- Kurye bilgileri varsa ekle
  IF courier_info IS NOT NULL THEN
    payload := payload || jsonb_build_object(
      'courier_id', NEW.courier_id,
      'courier_name', courier_info.owner_name,
      'courier_phone', courier_info.phone
    );
  END IF;
  
  -- Status'e özel alanlar ekle
  CASE NEW.status
    WHEN 'accepted' THEN
      payload := payload || jsonb_build_object('estimated_pickup_time', '10-15 dakika');
    
    WHEN 'picked_up' THEN
      payload := payload || jsonb_build_object('estimated_delivery_time', '20-25 dakika');
    
    WHEN 'delivered' THEN
      payload := payload || jsonb_build_object(
        'delivered_at', to_char(NEW.updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'collected_amount', COALESCE(NEW.declared_amount, 0),
        'payment_method', COALESCE(NEW.payment_method, 'cash')
      );
      -- Delivery photo URL varsa ekle
      IF NEW.delivery_photo_url IS NOT NULL THEN
        payload := payload || jsonb_build_object('delivery_photo_url', NEW.delivery_photo_url);
      END IF;
    
    WHEN 'cancelled' THEN
      payload := payload || jsonb_build_object(
        'cancelled_by', COALESCE(NEW.cancelled_by, 'system'),
        'cancellation_reason', COALESCE(NEW.cancellation_reason, 'Bilgi yok'),
        'cancelled_at', to_char(NEW.updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
      );
  END CASE;
  
  -- Payload'ı hazırla (Yemek App signature validation KAPALI - test mode)
  payload_text := payload::TEXT;
  timestamp_val := EXTRACT(EPOCH FROM NOW())::BIGINT;
  
  -- HMAC signature oluştur (gelecekte aktif olacak)
  signature := encode(
    hmac(payload_text || timestamp_val::TEXT, webhook_secret, 'sha256'),
    'hex'
  );
  
  RAISE NOTICE '[Yemek App Webhook] Sending payload: %', payload;
  RAISE NOTICE '[Yemek App Webhook] Signature: % (NOT SENT - validation disabled)', signature;
  RAISE NOTICE '[Yemek App Webhook] Timestamp: %', timestamp_val;
  
  -- HTTP POST isteği gönder (Authorization + Content-Type headers)
  BEGIN
    SELECT * INTO http_response
    FROM http((
      'POST',
      webhook_url,
      ARRAY[
        http_header('Content-Type', 'application/json'),
        http_header('Authorization', 'Bearer ' || yemek_app_anon_key)
      ],
      'application/json',
      payload_text
    )::http_request);
    
    RAISE NOTICE '[Yemek App Webhook] Response status: %', http_response.status;
    RAISE NOTICE '[Yemek App Webhook] Response body: %', http_response.content;
    
    -- Başarılı yanıt kontrolü (200-299)
    IF http_response.status >= 200 AND http_response.status < 300 THEN
      RAISE NOTICE '[Yemek App Webhook] ✅ Webhook sent successfully!';
    ELSE
      RAISE WARNING '[Yemek App Webhook] ⚠️ Webhook failed with status: %', http_response.status;
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING '[Yemek App Webhook] ❌ HTTP request failed: %', SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Eski trigger'ı sil
DROP TRIGGER IF EXISTS trigger_notify_yemek_app ON delivery_requests;

-- 4. Yeni trigger oluştur (UPDATE için)
CREATE TRIGGER trigger_notify_yemek_app
  AFTER UPDATE OF status ON delivery_requests
  FOR EACH ROW
  WHEN (NEW.source = 'yemek_app' AND 
        NEW.status IN ('accepted', 'picked_up', 'delivered', 'cancelled') AND
        OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION notify_yemek_app_on_status_change();

-- ✅ Yemek App Webhook Trigger oluşturuldu!
-- Webhook URL: https://avpbrcqbhxyctmwnxtmm.supabase.co/functions/v1/onlog-status-update
-- Secret: yemek_app_webhook_secret_2025
-- Aktif durumlar: accepted, picked_up, delivered, cancelled
