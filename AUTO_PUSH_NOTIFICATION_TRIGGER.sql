-- ============================================
-- OTOMATİK PUSH NOTIFICATION TRİGGER
-- HTTP Extension ile FCM'e direkt istek gönderir
-- ============================================

-- 1. HTTP Extension'ı aktif et (eğer yoksa)
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- 2. FCM gönderen trigger function
CREATE OR REPLACE FUNCTION notify_courier_with_fcm()
RETURNS TRIGGER AS $$
DECLARE
  merchant_name TEXT;
  courier_fcm_token TEXT;
  fcm_response http_response_result;
  fcm_payload JSON;
BEGIN
  -- Kurye FCM token'ını al
  SELECT fcm_token INTO courier_fcm_token
  FROM users
  WHERE id = NEW.courier_id;

  -- Token yoksa çık
  IF courier_fcm_token IS NULL THEN
    RAISE NOTICE '❌ Kurye FCM token bulunamadı: %', NEW.courier_id;
    RETURN NEW;
  END IF;

  -- Merchant adını al
  SELECT COALESCE(business_name, owner_name, full_name, 'Merchant')
  INTO merchant_name
  FROM users
  WHERE id = NEW.merchant_id;

  -- 1) Database bildirimi ekle (app içi için)
  INSERT INTO notifications (
    user_id,
    type,
    title,
    message,
    is_read,
    created_at
  ) VALUES (
    NEW.courier_id,
    'delivery',
    'Yeni Teslimat!',
    'Tutar: ' || NEW.declared_amount || ' TL - Kazanç: ' || NEW.courier_payment_due || ' TL',
    false,
    NOW()
  );

  -- 2) FCM Payload hazırla
  fcm_payload := json_build_object(
    'to', courier_fcm_token,
    'notification', json_build_object(
      'title', '🚀 Yeni Teslimat İsteği!',
      'body', merchant_name || ' - Tutar: ' || NEW.declared_amount || ' TL - Kazanç: ' || NEW.courier_payment_due || ' TL',
      'sound', 'default'
    ),
    'data', json_build_object(
      'type', 'new_delivery_request',
      'delivery_request_id', NEW.id,
      'merchant_name', merchant_name,
      'declared_amount', NEW.declared_amount,
      'courier_payment_due', NEW.courier_payment_due
    ),
    'android', json_build_object(
      'priority', 'high',
      'notification', json_build_object(
        'channel_id', 'new_order_channel',
        'sound', 'default'
      )
    )
  );

  -- 3) FCM'e HTTP POST gönder
  -- NOT: FCM_SERVER_KEY'i buraya yazmanız gerekiyor!
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

  -- 4) Sonucu logla
  IF fcm_response.status = 200 THEN
    RAISE NOTICE '✅ FCM bildirimi gönderildi: Courier=%, Response=%', NEW.courier_id, fcm_response.content;
  ELSE
    RAISE WARNING '❌ FCM hatası: Status=%, Content=%', fcm_response.status, fcm_response.content;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Eski trigger'ı sil, yeni trigger ekle
DROP TRIGGER IF EXISTS trigger_notify_courier_on_new_delivery ON delivery_requests;

CREATE TRIGGER trigger_notify_courier_with_fcm
AFTER INSERT ON delivery_requests
FOR EACH ROW
EXECUTE FUNCTION notify_courier_with_fcm();

-- 4. Test
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_notify_courier_with_fcm';