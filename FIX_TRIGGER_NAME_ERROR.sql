-- ONLOG - Trigger Fonksiyonunu Düzelt
-- "name" kolonu yerine "email" kullan

CREATE OR REPLACE FUNCTION notify_courier_on_delivery_assigned()
RETURNS TRIGGER AS $$
DECLARE
  courier_fcm_token TEXT;
  merchant_email TEXT;
  notification_data JSONB;
BEGIN
  -- Kurye FCM token'ını al
  SELECT fcm_token INTO courier_fcm_token
  FROM users
  WHERE id = NEW.courier_id;

  -- Eğer kurye FCM token'ı yoksa çık
  IF courier_fcm_token IS NULL THEN
    RAISE NOTICE 'Kurye FCM token bulunamadı: %', NEW.courier_id;
    RETURN NEW;
  END IF;

  -- Merchant email'ini al (name kolonu yok)
  SELECT email INTO merchant_email
  FROM users
  WHERE id = NEW.merchant_id;

  -- Bildirim datasını hazırla
  notification_data := jsonb_build_object(
    'type', 'new_delivery_request',
    'delivery_request_id', NEW.id,
    'merchant_id', NEW.merchant_id,
    'merchant_email', COALESCE(merchant_email, 'Merchant'),
    'package_count', COALESCE(NEW.package_count, 1),
    'declared_amount', COALESCE(NEW.declared_amount, 0)
  );

  -- notification_queue'ya ekle
  INSERT INTO notification_queue (
    user_id,
    fcm_token,
    title,
    body,
    data,
    status,
    created_at
  ) VALUES (
    NEW.courier_id,
    courier_fcm_token,
    '🚀 Yeni Teslimat İsteği!',
    COALESCE(merchant_email, 'Merchant') || ' - Yeni teslimat',
    notification_data,
    'pending',
    NOW()
  );

  RAISE NOTICE 'Bildirim kuyruğa eklendi: Kurye % için', NEW.courier_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger zaten mevcut, sadece fonksiyonu güncelledik
SELECT 'Trigger fonksiyonu güncellendi - name hatası düzeltildi' AS status;
