-- ONLOG - Teslimat Oluşturulduğunda Otomatik Bildirim
-- INSERT ve UPDATE için trigger oluştur

-- Önce mevcut trigger'ları kontrol et
DROP TRIGGER IF EXISTS trigger_notify_courier_on_assignment ON delivery_requests;
DROP TRIGGER IF EXISTS teslim_edilen_kurye_tetikle ON delivery_requests;

-- notify_courier_on_delivery_assigned fonksiyonunu oluştur/güncelle
CREATE OR REPLACE FUNCTION notify_courier_on_delivery_assigned()
RETURNS TRIGGER AS $$
DECLARE
  courier_fcm_token TEXT;
  merchant_name TEXT;
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

  -- Merchant adını al
  SELECT name INTO merchant_name
  FROM users
  WHERE id = NEW.merchant_id;

  -- Bildirim datasını hazırla
  notification_data := jsonb_build_object(
    'type', 'new_delivery_request',
    'delivery_request_id', NEW.id,
    'merchant_id', NEW.merchant_id,
    'merchant_name', COALESCE(merchant_name, 'Merchant'),
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
    COALESCE(merchant_name, 'Merchant') || ' - Yeni teslimat',
    notification_data,
    'pending',
    NOW()
  );

  RAISE NOTICE 'Bildirim kuyruğa eklendi: Kurye % için', NEW.courier_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı oluştur - INSERT ve UPDATE için
CREATE TRIGGER trigger_notify_courier_on_assignment
  AFTER INSERT OR UPDATE OF courier_id
  ON delivery_requests
  FOR EACH ROW
  WHEN (NEW.courier_id IS NOT NULL)
  EXECUTE FUNCTION notify_courier_on_delivery_assigned();

-- Test mesajı
SELECT 'Trigger başarıyla oluşturuldu - INSERT ve UPDATE' AS status;

-- Trigger'ları listele
SELECT 
    trigger_name,
    string_agg(event_manipulation, ', ' ORDER BY event_manipulation) as events
FROM information_schema.triggers
WHERE trigger_name = 'trigger_notify_courier_on_assignment'
GROUP BY trigger_name;
