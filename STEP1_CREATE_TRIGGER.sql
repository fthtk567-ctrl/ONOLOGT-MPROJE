-- 🎯 ADIM 1: TRİGGER OLUŞTUR
DROP TRIGGER IF EXISTS trigger_auto_reassign_delivery ON delivery_requests;

CREATE TRIGGER trigger_auto_reassign_delivery
  AFTER UPDATE ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_reassign_rejected_delivery();