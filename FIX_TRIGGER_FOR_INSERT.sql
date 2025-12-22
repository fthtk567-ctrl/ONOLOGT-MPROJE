-- ONLOG - Trigger'ı Hem INSERT Hem UPDATE'e Ayarla
-- Teslimat ilk oluşturulduğunda da bildirim gönder

-- Önce eski trigger'ı kaldır
DROP TRIGGER IF EXISTS trigger_notify_courier_on_assignment ON delivery_requests;

-- Yeni trigger - INSERT ve UPDATE'te çalışsın
CREATE TRIGGER trigger_notify_courier_on_assignment
  AFTER INSERT OR UPDATE OF courier_id
  ON delivery_requests
  FOR EACH ROW
  WHEN (NEW.courier_id IS NOT NULL)
  EXECUTE FUNCTION notify_courier_on_delivery_assigned();

-- Test için log
SELECT 'Trigger güncellendi - INSERT ve UPDATE'::text as status;
