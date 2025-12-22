-- ============================================
-- BİLDİRİM TRİGGER'LARINI GÜNCELLE
-- ============================================
-- Hem INSERT hem UPDATE'te çalışsın
-- ============================================

-- 1. Eski trigger'ları sil
DROP TRIGGER IF EXISTS trigger_notify_courier_simple ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_add_notification_on_delivery_request ON delivery_requests;

-- 2. YENİ TRIGGER: Yeni teslimat oluştuğunda (INSERT)
CREATE OR REPLACE TRIGGER trigger_notify_courier_on_insert
AFTER INSERT
ON delivery_requests
FOR EACH ROW
WHEN (NEW.courier_id IS NOT NULL)
EXECUTE FUNCTION notify_courier_simple();

-- 3. YENİ TRIGGER: Kurye atandığında (UPDATE)
CREATE OR REPLACE TRIGGER trigger_notify_courier_on_update
AFTER UPDATE OF courier_id, status
ON delivery_requests
FOR EACH ROW
WHEN (
  (NEW.courier_id IS NOT NULL AND OLD.courier_id IS NULL)
  OR (NEW.status != OLD.status)
)
EXECUTE FUNCTION notify_courier_simple();

-- 4. YENİ TRIGGER: Notifications tablosuna kayıt (INSERT)
CREATE OR REPLACE TRIGGER trigger_add_notification_on_insert
AFTER INSERT
ON delivery_requests
FOR EACH ROW
WHEN (NEW.courier_id IS NOT NULL)
EXECUTE FUNCTION add_notification_to_queue();

-- 5. YENİ TRIGGER: Notifications tablosuna kayıt (UPDATE)
CREATE OR REPLACE TRIGGER trigger_add_notification_on_update
AFTER UPDATE OF courier_id
ON delivery_requests
FOR EACH ROW
WHEN (NEW.courier_id IS NOT NULL AND OLD.courier_id IS NULL)
EXECUTE FUNCTION add_notification_to_queue();

-- ✅ AÇIKLAMA:
-- INSERT: Yeni teslimat oluştuğunda (courier_id varsa)
-- UPDATE: courier_id NULL'dan dolu hale geldiğinde (kurye atandığında)
-- UPDATE: status değiştiğinde (örn: assigned → accepted)

-- ✅ Supabase SQL Editor'da çalıştır
