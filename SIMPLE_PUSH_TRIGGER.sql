-- ============================================
-- BASİT PUSH NOTIFICATION - CURL İLE
-- ============================================
CREATE OR REPLACE FUNCTION notify_courier_simple()
RETURNS TRIGGER AS $$
DECLARE
  merchant_name TEXT;
  courier_fcm_token TEXT;
  curl_command TEXT;
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

  -- 1) Database bildirimi ekle
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

  -- 2) FCM komutu logla (manuel gönderim için)
  curl_command := 'curl -X POST https://fcm.googleapis.com/fcm/send ' ||
    '-H "Authorization: key=AIzaSyBWO_lr-73AxfBlulvRD0W_wA0fzuTHAXg" ' ||
    '-H "Content-Type: application/json" ' ||
    '-d ''{"to":"' || courier_fcm_token || '","notification":{"title":"🚀 Yeni Teslimat İsteği!","body":"' || COALESCE(merchant_name, 'Merchant') || ' - Tutar: ' || COALESCE(NEW.declared_amount::text, '0') || ' TL - Kazanç: ' || COALESCE(NEW.courier_payment_due::text, '0') || ' TL"},"android":{"priority":"high","notification":{"channel_id":"new_order_channel"}}}'';';

  RAISE NOTICE '📱 FCM Komutu: %', curl_command;
  RAISE NOTICE '✅ Bildirim hazırlandı: Courier=%, Merchant=%', NEW.courier_id, merchant_name;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger değiştir - TÜM ESKİ TRİGGERLARI SİL
DROP TRIGGER IF EXISTS trigger_notify_courier_with_fcm ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_on_new_delivery ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_simple ON delivery_requests;

CREATE TRIGGER trigger_notify_courier_simple
AFTER INSERT ON delivery_requests
FOR EACH ROW
EXECUTE FUNCTION notify_courier_simple();

-- Test
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_name = 'trigger_notify_courier_simple';