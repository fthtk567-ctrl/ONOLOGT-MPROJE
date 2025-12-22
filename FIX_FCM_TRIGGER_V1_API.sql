-- ============================================
-- FCM TRİGGER'I YENİ V1 API İLE GÜNCELLE
-- Legacy API yerine OAuth2 + FCM v1 kullan
-- ============================================

-- 1. Yeni FCM v1 gönderen function (OAuth2 destekli)
CREATE OR REPLACE FUNCTION notify_courier_with_fcm()
RETURNS TRIGGER AS $$
DECLARE
  merchant_name TEXT;
  courier_fcm_token TEXT;
BEGIN
  -- Kurye FCM token'ını al
  SELECT fcm_token INTO courier_fcm_token
  FROM users
  WHERE id = NEW.courier_id;

  -- Token yoksa çık
  IF courier_fcm_token IS NULL THEN
    RAISE NOTICE 'Kurye FCM token yok: %', NEW.courier_id;
    RETURN NEW;
  END IF;

  -- Merchant adını al
  SELECT COALESCE(business_name, owner_name, full_name, 'Merchant')
  INTO merchant_name
  FROM users
  WHERE id = NEW.merchant_id;

  -- notifications tablosuna kayıt ekle (Edge Function otomatik gönderecek)
  INSERT INTO notifications (
    user_id,
    fcm_token,
    title,
    message,
    notification_status,
    data,
    created_at
  ) VALUES (
    NEW.courier_id,
    courier_fcm_token,
    '🚀 Yeni Teslimat İsteği!',
    merchant_name || ' - Tutar: ' || NEW.declared_amount || ' TL - Kazanç: ' || NEW.courier_payment_due || ' TL',
    'pending',
    json_build_object(
      'type', 'new_delivery_request',
      'delivery_request_id', NEW.id,
      'merchant_name', merchant_name,
      'declared_amount', NEW.declared_amount,
      'courier_payment_due', NEW.courier_payment_due
    ),
    NOW()
  );

  RAISE NOTICE 'Notification kaydı oluşturuldu: Courier=%', NEW.courier_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Eski trigger'ları kaldır
DROP TRIGGER IF EXISTS trigger_send_courier_notification ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_on_insert ON delivery_requests;

-- 3. Yeni trigger ekle (sadece courier_id atandığında çalışsın)
CREATE TRIGGER trigger_send_courier_notification
  AFTER INSERT OR UPDATE OF courier_id ON delivery_requests
  FOR EACH ROW
  WHEN (NEW.courier_id IS NOT NULL)
  EXECUTE FUNCTION notify_courier_with_fcm();

-- 4. Kontrol
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND trigger_name = 'trigger_send_courier_notification';

-- Sonuç: 1 satır dönmeli (trigger aktif) ✅
