-- ============================================
-- KURYE BİLDİRİM TRİGGER'I OLUŞTUR
-- ============================================
-- Yeni delivery_request oluşturulduğunda courier'a bildirim gönder

-- 1️⃣ Fonksiyonu oluştur
CREATE OR REPLACE FUNCTION notify_courier_new_delivery()
RETURNS TRIGGER AS $$
DECLARE
  courier_fcm_token TEXT;
  merchant_name TEXT;
BEGIN
  -- Courier'ın FCM token'ını al
  SELECT fcm_token INTO courier_fcm_token
  FROM users
  WHERE id = NEW.courier_id;
  
  -- Merchant adını al
  SELECT business_name INTO merchant_name
  FROM users
  WHERE id = NEW.merchant_id;
  
  -- notifications tablosuna ekle
  INSERT INTO notifications (
    user_id,
    type,
    title,
    message,
    is_read,
    created_at
  ) VALUES (
    NEW.courier_id,
    'new_delivery',
    'Yeni Teslimat!',
    COALESCE(merchant_name, 'Bir işletme') || ' - ' || NEW.package_count || ' paket - ' || NEW.declared_amount || ' TL (Kazanç: ' || NEW.courier_payment_due || ' TL)',
    false,
    NOW()
  );
  
  RAISE NOTICE 'Bildirim olusturuldu: Courier=%, Delivery=%', NEW.courier_id, NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2️⃣ Trigger'ı oluştur
DROP TRIGGER IF EXISTS trigger_notify_courier_on_new_delivery ON delivery_requests;

CREATE TRIGGER trigger_notify_courier_on_new_delivery
AFTER INSERT ON delivery_requests
FOR EACH ROW
WHEN (NEW.courier_id IS NOT NULL) -- Sadece courier atanmışsa
EXECUTE FUNCTION notify_courier_new_delivery();

-- 3️⃣ Test için kontrol
SELECT 
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'trigger_notify_courier_on_new_delivery';

-- 4️⃣ Mevcut bildirimler
SELECT 
  n.id,
  u.email as courier_email,
  n.type,
  n.title,
  n.message,
  n.is_read,
  TO_CHAR(n.created_at, 'DD.MM.YYYY HH24:MI:SS') as olusturulma
FROM notifications n
JOIN users u ON n.user_id = u.id
WHERE u.role = 'courier'
ORDER BY n.created_at DESC
LIMIT 10;
