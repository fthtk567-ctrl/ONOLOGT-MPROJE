-- ============================================
-- BİLDİRİM SİSTEMİ - SADECE DATABASE (FCM YOK!)
-- ============================================

-- FCM Legacy API çalışmıyor, o yüzden sadece database'e yaz
-- Flutter Local Notifications ile Realtime listener'dan göster!

-- 1. Notification ekleyen fonksiyon (FCM YOK!)
CREATE OR REPLACE FUNCTION add_notification_on_courier_assign()
RETURNS TRIGGER AS $$
DECLARE
  merchant_name TEXT;
BEGIN
  -- Sadece courier atandığında
  IF NEW.courier_id IS NOT NULL AND (OLD.courier_id IS NULL OR OLD.courier_id != NEW.courier_id) THEN
    
    -- Merchant adını al
    SELECT COALESCE(business_name, owner_name, full_name, 'Merchant')
    INTO merchant_name
    FROM users
    WHERE id = NEW.merchant_id;
    
    -- Notification tablosuna ekle (type = 'delivery' - constraint'e uygun!)
    INSERT INTO notifications (
      user_id,
      title,
      message,
      type,
      is_read,
      created_at
    ) VALUES (
      NEW.courier_id,
      '🚀 Yeni Teslimat İsteği!',
      merchant_name || ' - Tutar: ' || NEW.declared_amount || ' TL',
      'delivery',
      false,
      NOW()
    );
    
    RAISE NOTICE '✅ Bildirim eklendi (Realtime listener yakalayacak!)';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Trigger'ları yeniden oluştur
DROP TRIGGER IF EXISTS trigger_add_notification_on_insert ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_add_notification_on_update ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_with_fcm ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_fcm_on_update ON delivery_requests;

-- INSERT trigger
CREATE TRIGGER trigger_add_notification_on_insert
AFTER INSERT ON delivery_requests
FOR EACH ROW
WHEN (NEW.courier_id IS NOT NULL)
EXECUTE FUNCTION add_notification_on_courier_assign();

-- UPDATE trigger
CREATE TRIGGER trigger_add_notification_on_update
AFTER UPDATE ON delivery_requests
FOR EACH ROW
WHEN (OLD.courier_id IS NULL AND NEW.courier_id IS NOT NULL)
EXECUTE FUNCTION add_notification_on_courier_assign();

-- 3. Kontrol et
SELECT 
  trigger_name,
  event_object_table,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'delivery_requests'
ORDER BY trigger_name;

-- Artık sistem şöyle çalışıyor:
-- 1. Merchant Panel: Delivery oluştur + courier_id ata
-- 2. Database Trigger: notifications tablosuna INSERT
-- 3. Supabase Realtime: notifications değişikliğini yayınla
-- 4. Courier App: Realtime listener bildirim yakalar
-- 5. Flutter Local Notifications: Native bildirim göster! 📱🔔
SELECT '✅ Bildirim sistemi güncellendi! Artık FCM değil, Realtime + Local Notifications kullanılıyor.' as status;
