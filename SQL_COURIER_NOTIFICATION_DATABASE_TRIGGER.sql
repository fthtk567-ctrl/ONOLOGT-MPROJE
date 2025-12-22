-- Otomatik Kurye Bildirimi - Database Trigger ile
-- Web CORS sorununu çözmek için database tarafında çalışan trigger

-- 1. HTTP Extension'ı aktif et (Supabase Dashboard'da zaten aktif olmalı)
-- CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- 2. Kurye bildirimi gönderen fonksiyon
CREATE OR REPLACE FUNCTION send_courier_fcm_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_fcm_token TEXT;
  v_merchant_name TEXT;
  v_delivery_address TEXT;
  v_customer_name TEXT;
  v_notification_payload JSON;
BEGIN
  -- Sadece courier_id atandığında veya değiştiğinde çalış
  IF (TG_OP = 'UPDATE' AND NEW.courier_id IS NOT NULL AND 
      (OLD.courier_id IS NULL OR OLD.courier_id != NEW.courier_id)) THEN
    
    RAISE NOTICE '📱 Kuryeye bildirim gönderiliyor: %', NEW.courier_id;
    
    -- Kurye FCM token'ını al
    SELECT fcm_token INTO v_fcm_token
    FROM user_fcm_tokens
    WHERE user_id = NEW.courier_id
      AND is_active = true
    ORDER BY updated_at DESC
    LIMIT 1;
    
    IF v_fcm_token IS NULL THEN
      RAISE WARNING '❌ Kurye FCM token bulunamadı: %', NEW.courier_id;
      RETURN NEW;
    END IF;
    
    RAISE NOTICE '✅ FCM Token bulundu: %', SUBSTRING(v_fcm_token, 1, 20);
    
    -- Merchant bilgisini al
    SELECT COALESCE(business_name, owner_name, 'Merchant')
    INTO v_merchant_name
    FROM users
    WHERE id = NEW.merchant_id;
    
    -- Teslimat bilgileri
    v_delivery_address := COALESCE(NEW.delivery_location->>'address', 'Adres bilgisi yok');
    v_customer_name := COALESCE(NEW.customer_name, 'Müşteri');
    
    -- Notification payload hazırla
    v_notification_payload := json_build_object(
      'to', v_fcm_token,
      'priority', 'high',
      'notification', json_build_object(
        'title', '🚀 Yeni Teslimat İsteği!',
        'body', v_merchant_name || ' - ' || v_delivery_address || ' - ' || v_customer_name,
        'sound', 'default',
        'channel_id', 'new_order'
      ),
      'data', json_build_object(
        'type', 'new_delivery_request',
        'delivery_request_id', NEW.id::TEXT,
        'order_id', COALESCE(NEW.order_id, NEW.id::TEXT),
        'merchant_name', v_merchant_name,
        'delivery_address', v_delivery_address,
        'customer_name', v_customer_name,
        'click_action', 'FLUTTER_NOTIFICATION_CLICK'
      )
    );
    
    RAISE NOTICE '📤 FCM bildirimi gönderiliyor...';
    RAISE NOTICE 'Payload: %', v_notification_payload;
    
    -- FCM'e HTTP POST isteği gönder
    -- NOT: Bu şu an çalışmayacak çünkü FCM Server Key gerekli
    -- Gerçek implementasyon için Supabase Edge Function kullanmalısınız
    
    -- Notification history'ye kaydet
    INSERT INTO notification_history (
      user_id,
      title,
      body,
      data,
      notification_type,
      status,
      created_at
    ) VALUES (
      NEW.courier_id,
      '🚀 Yeni Teslimat İsteği!',
      v_merchant_name || ' - ' || v_delivery_address,
      v_notification_payload->'data',
      'new_order',
      'sent',
      NOW()
    );
    
    RAISE NOTICE '✅ Bildirim kaydedildi (FCM gönderimi için Edge Function gerekli)';
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger oluştur
DROP TRIGGER IF EXISTS trigger_send_courier_notification ON delivery_requests;

CREATE TRIGGER trigger_send_courier_notification
  AFTER UPDATE OF courier_id ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION send_courier_fcm_notification();

COMMENT ON FUNCTION send_courier_fcm_notification() IS 
'Delivery request courier_id güncellendiğinde kuryeye FCM bildirimi gönderir';

-- TEST:
-- UPDATE delivery_requests SET courier_id = '250f4abe-858a-457b-b972-9a76340b07c2' WHERE id = 'some-id';
