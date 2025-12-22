-- Mevcut trigger'ı sil ve yeniden oluştur
DROP TRIGGER trigger_auto_reassign_delivery ON delivery_requests;

CREATE TRIGGER trigger_auto_reassign_delivery
    BEFORE UPDATE OF status ON delivery_requests
    FOR EACH ROW
    WHEN (NEW.status = 'rejected')
    EXECUTE FUNCTION auto_reassign_rejected_delivery();
