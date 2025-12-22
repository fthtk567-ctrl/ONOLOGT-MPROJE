-- ============================================
-- PUSH NOTIFICATION İÇİN TRİGGER (EDGE FUNCTION)
-- ============================================
CREATE OR REPLACE FUNCTION notify_courier_with_push()
RETURNS TRIGGER AS $$
DECLARE
  merchant_name TEXT;
  http_request_id BIGINT;
BEGIN
  -- Merchant adını al
  SELECT COALESCE(business_name, owner_name, full_name, 'Merchant')
  INTO merchant_name
  FROM users
  WHERE id = NEW.merchant_id;

  -- 1) Database bildirimi ekle (eski sistem)
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

  -- 2) Edge Function'ı çağır (PUSH NOTIFICATION)
  SELECT
    extensions.http_post(
      url := 'https://your-project-ref.supabase.co/functions/v1/send-push-notification',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.settings.service_role_key', true) || '"}',
      body := json_build_object(
        'delivery_request_id', NEW.id,
        'courier_id', NEW.courier_id,
        'merchant_name', merchant_name,
        'declared_amount', NEW.declared_amount,
        'courier_payment_due', NEW.courier_payment_due
      )::text
    ) INTO http_request_id;

  RAISE NOTICE '📱 Edge Function çağırıldı: % - HTTP Request ID: %', NEW.courier_id, http_request_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eski trigger'ı sil, yeni trigger ekle
DROP TRIGGER IF EXISTS trigger_notify_courier_on_new_delivery ON delivery_requests;

CREATE TRIGGER trigger_notify_courier_with_push
AFTER INSERT ON delivery_requests
FOR EACH ROW
EXECUTE FUNCTION notify_courier_with_push();

-- Trigger kontrol
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_notify_courier_with_push';