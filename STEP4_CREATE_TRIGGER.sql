-- ADIM 4: Trigger oluştur
CREATE TRIGGER trigger_auto_reassign_delivery
    BEFORE UPDATE OF status ON delivery_requests
    FOR EACH ROW
    WHEN (NEW.status = 'rejected')
    EXECUTE FUNCTION auto_reassign_rejected_delivery();
