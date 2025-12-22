-- ============================================
-- notify_courier_with_fcm FONKSİYONUNU DÜZELT
-- type kolonunu ekle
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_courier_with_fcm()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
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

  -- ⭐ DÜZELTME: type kolonunu ekledik
  INSERT INTO notifications (
    user_id,
    fcm_token,
    type,           -- ⭐ YENİ EKLENEN
    title,
    message,
    notification_status,
    data,
    created_at
  ) VALUES (
    NEW.courier_id,
    courier_fcm_token,
    'delivery',     -- ⭐ YENİ EKLENEN
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

  RAISE NOTICE '✅ Notification kaydı oluşturuldu (type=delivery): Courier=%', NEW.courier_id;
  
  RETURN NEW;
END;
$function$;

-- ✅ BAŞARILI MESAJI
SELECT '✅ notify_courier_with_fcm fonksiyonu düzeltildi! Artık type kolonu eklenecek.' as status;
