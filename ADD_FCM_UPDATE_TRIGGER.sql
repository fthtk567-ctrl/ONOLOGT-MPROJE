-- ============================================
-- FCM PUSH NOTIFICATION - UPDATE TRİGGER EKLE
-- ============================================

-- UPDATE trigger ekle (INSERT'e ek olarak)
DROP TRIGGER IF EXISTS trigger_notify_courier_fcm_on_update ON delivery_requests;

CREATE TRIGGER trigger_notify_courier_fcm_on_update
AFTER UPDATE ON delivery_requests
FOR EACH ROW
WHEN (
  OLD.courier_id IS NULL AND 
  NEW.courier_id IS NOT NULL
)
EXECUTE FUNCTION notify_courier_with_fcm();

-- Trigger'ları kontrol et
SELECT trigger_name, event_object_table, event_manipulation
FROM information_schema.triggers 
WHERE trigger_name LIKE '%fcm%'
ORDER BY trigger_name;
