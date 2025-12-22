-- ============================================
-- FCM PUSH NOTIFICATION TRİGGER (DÜZELTİLMİŞ)
-- ============================================

-- 1. HTTP Extension'ı aktif et
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- 2. FCM gönderen trigger function (TİP HATASI DÜZELTİLDİ)
CREATE OR REPLACE FUNCTION notify_courier_with_fcm()
RETURNS TRIGGER AS $$
DECLARE
  merchant_name TEXT;
  courier_fcm_token TEXT;
  fcm_response RECORD;  -- TİP DEĞİŞTİRİLDİ: http_response yerine RECORD
  fcm_payload JSON;
BEGIN
  -- Kurye FCM token'ını al
  SELECT fcm_token INTO courier_fcm_token
  FROM users
  WHERE id = NEW.courier_id;

  IF courier_fcm_token IS NULL THEN
    RAISE NOTICE '❌ Kurye FCM token bulunamadı: %', NEW.courier_id;
    RETURN NEW;
  END IF;

  -- Merchant adını al
  SELECT COALESCE(business_name, owner_name, full_name, 'Merchant')
  INTO merchant_name
  FROM users
  WHERE id = NEW.merchant_id;

  -- FCM Payload hazırla
  fcm_payload := json_build_object(
    'to', courier_fcm_token,
    'notification', json_build_object(
      'title', '🚀 Yeni Teslimat İsteği!',
      'body', merchant_name || ' - Tutar: ' || NEW.declared_amount || ' TL',
      'sound', 'default'
    ),
    'data', json_build_object(
      'type', 'new_delivery_request',
      'delivery_request_id', NEW.id::text,
      'merchant_name', merchant_name,
      'declared_amount', NEW.declared_amount::text
    ),
    'android', json_build_object(
      'priority', 'high',
      'notification', json_build_object(
        'channel_id', 'new_order_channel',
        'sound', 'default'
      )
    )
  );

  -- FCM'e HTTP POST gönder
  BEGIN
    SELECT * INTO fcm_response FROM extensions.http((
      'POST',
      'https://fcm.googleapis.com/fcm/send',
      ARRAY[
        extensions.http_header('Authorization', 'key=AIzaSyBWO_lr-73AxfBlulvRD0W_wA0fzuTHAXg'),
        extensions.http_header('Content-Type', 'application/json')
      ],
      'application/json',
      fcm_payload::text
    )::extensions.http_request);

    -- Sonucu kontrol et
    IF fcm_response.status = 200 THEN
      RAISE NOTICE '✅ FCM bildirimi gönderildi! Courier: %', NEW.courier_id;
    ELSE
      RAISE WARNING '❌ FCM hatası: Status=%, Content=%', fcm_response.status, fcm_response.content;
    END IF;
    
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING '❌ FCM HTTP isteği başarısız: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Yeni trigger ekle (eski varsa önce sil)
DROP TRIGGER IF EXISTS trigger_notify_courier_with_fcm ON delivery_requests;

CREATE TRIGGER trigger_notify_courier_with_fcm
AFTER INSERT ON delivery_requests
FOR EACH ROW
WHEN (NEW.courier_id IS NOT NULL)
EXECUTE FUNCTION notify_courier_with_fcm();

-- 4. Test - trigger oluştu mu?
SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_notify_courier_with_fcm';
