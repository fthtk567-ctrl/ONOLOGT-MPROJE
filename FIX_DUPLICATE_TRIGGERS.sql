-- TÜM ESKİ TRIGGER'LARI SİL VE TEK TRIGGER BIRAK

-- 1. Tüm eski trigger'ları sil
DROP TRIGGER IF EXISTS trigger_add_notification_on_insert ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_add_notification_on_update ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_new_delivery ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_on_assign ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_on_insert ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_on_update ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_simple ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_via_edge_function ON delivery_requests;
DROP TRIGGER IF EXISTS on_notification_insert_trigger ON notifications;

-- 2. YENİ TEK TRIGGER - Sadece INSERT olduğunda bildirim oluştur
CREATE OR REPLACE FUNCTION create_courier_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Sadece yeni teslimat isteği oluşturulduğunda bildirim ekle
  INSERT INTO notifications (
    user_id,
    fcm_token,
    type,
    title,
    message,
    notification_status,
    data,
    created_at
  )
  SELECT 
    NEW.courier_id,
    u.fcm_token,
    'delivery',
    '🚚 Yeni Teslimat Ataması',
    NEW.declared_amount::TEXT || ' TL değerinde yeni bir teslimat atandı!',
    'pending',
    jsonb_build_object(
      'delivery_request_id', NEW.id,
      'merchant_id', NEW.merchant_id,
      'declared_amount', NEW.declared_amount
    ),
    NOW()
  FROM users u
  WHERE u.id = NEW.courier_id
  AND u.fcm_token IS NOT NULL;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. TEK TRIGGER ekle - Sadece INSERT olduğunda
DROP TRIGGER IF EXISTS trigger_single_notification ON delivery_requests;

CREATE TRIGGER trigger_single_notification
AFTER INSERT ON delivery_requests
FOR EACH ROW
WHEN (NEW.courier_id IS NOT NULL)
EXECUTE FUNCTION create_courier_notification();

-- 4. Kontrol
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
AND trigger_schema = 'public'
ORDER BY trigger_name;
