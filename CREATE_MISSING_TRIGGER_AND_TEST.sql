-- 🚀 TRİGGER OLUŞTUR - YOKMUŞ MEĞER!

-- Önce varsa sil
DROP TRIGGER IF EXISTS trigger_auto_reassign_delivery ON delivery_requests;

-- Yeniden oluştur
CREATE TRIGGER trigger_auto_reassign_delivery
  AFTER UPDATE ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_reassign_rejected_delivery();

-- Kontrol: Trigger oluştu mu?
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  '✅ Trigger başarıyla oluşturuldu!' as durum
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_reassign_delivery';

-- ŞİMDİ TEST EDELIM: Siparişi tekrar pending'e al
UPDATE delivery_requests 
SET status = 'pending'
WHERE id = 'b2be4262-96a1-43c9-8de9-04603bf5485a';

-- Sonuç kontrol
SELECT 
  status,
  courier_id,
  rejected_by,
  (SELECT full_name FROM users WHERE id = courier_id) as "Atanan Kurye",
  (SELECT full_name FROM users WHERE id = rejected_by) as "Red Eden",
  CASE 
    WHEN courier_id IS NOT NULL AND rejected_by IS NOT NULL 
      THEN '✅ BAŞARILI! Trigger çalıştı!'
    ELSE '❌ Trigger çalışmadı'
  END as "Sonuç"
FROM delivery_requests
WHERE id = 'b2be4262-96a1-43c9-8de9-04603bf5485a';